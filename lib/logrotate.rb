require 'date'
require 'pathname'
require 'time'

class Logrotate < Struct.new(:directory, :current, :pattern, :expiry_base, :backoff)
  File = Struct.new(:path, :age)

  def initialize(*args)
    super
    self.directory = Pathname.new(directory) \
      unless Pathname.respond_to?(:children)
  end

  # Find the files matching our pattern, arrange by age
  def find_files
    ret = []
    directory.children.each do |f|
      begin
        time = Time.strptime(f.basename.to_s, pattern)
        ret << File.new(f, (Date.today - time.to_date).to_i)
      rescue ArgumentError
      end
    end
    ret.sort_by(&:age)
  end

  # Choose n items from an array, rougly evenly spaced, prioritizing the end
  def spaced(array, n)
    return [] if array.empty? || n <= 0
    slice = (array.size.to_f / n).ceil
    array.reverse.each_slice(slice).map(&:first).reverse
  end

  # Decide what files to keep
  def choose_files(files)
    keep = [files.shift] # Always keep the most recent

    # Keep backups at exponential time distances
    (keep.size + 1).upto(Float::INFINITY) do |limit|
      break if files.empty?
      age_limit = expiry_base * (backoff ** limit)

      # If backoff is low, consecutive limits might have same age_limit.
      # Just skip the first
      next if age_limit.to_i == (age_limit * backoff).to_i

      # Keep up to `limit` items newer than this age
      newer, files = *files.partition { |f| f.age < age_limit }
      keep.concat(spaced(newer, limit - keep.size))
    end
    keep
  end

  def rotate
    files = find_files
    keep = choose_files(files)

    # Delete the old ones
    (files - keep).each { |b| b.path.unlink }

    # Symlink the most recent
    return if keep.empty?
    first = keep.first.path
    link = directory + current
    link.unlink if link.symlink? || link.exist?
    link.make_symlink(first.basename)
  end
end

if __FILE__ == $0
  # Show what ages of files will be kept on each day
  base, backoff = *ARGV.map(&:to_f)
  rotate = Logrotate.new('', nil, nil, base, backoff)

  files = []
  0.upto(200).each do
    files.each { |f| f.age += 1 }
    files << Logrotate::File.new(nil, 0)
    files.sort_by!(&:age)

    files = rotate.choose_files(files)
    p files.map(&:age)
  end
end
