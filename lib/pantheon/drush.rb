require 'open3'
require 'tempfile'

class Pantheon
class Environment
  def drush(*args)
    # Allow specifying an output file as the first argument
    out = args.first.respond_to?(:fileno) ? args.shift : nil

    # Don't bother with host keys, and don't print a message
    cmd = ['ssh', '-q', '-oStrictHostKeyChecking=no',
      '-oUserKnownHostsFile=/dev/null']
    # Use specified SSH key
    cmd << '-i' << @pantheon.sshkey
    # Pantheon connection info
    cmd << '-p2222' << '-oAddressFamily=inet'
    cmd << '-l' << "#{name}.#{site.id}"
    cmd << "appserver.#{name}.#{site.id}.drush.in"
    cmd << 'drush'
    cmd.concat(args)

    output = nil
    if out
      ok = system(*cmd, :out => out.fileno)
    else
      output, status = Open3.capture2(*cmd)
      ok = status.success?
    end
    raise "Drush failure: #{args.join ' '}" unless ok
    output
  end

  # Get the Drush major version, as an integer. May be in environment info,
  # or may require a request.
  def drush_version
    super || drush('version', '--pipe').to_i
  end

  # Drush sometimes puts garbage error messages at the start of a file.
  # Try to detect this, and fix it.
  def gzfix(file, dest)
    gzip_header = "\x1f\x8b".force_encoding(Encoding::ASCII_8BIT)
    limit = 1024

    # Read a few lines, looking for gzip header
    file.rewind
    10.times do |i|
      line = file.readline(limit).force_encoding(Encoding::ASCII_8BIT)
      if line[0,2] == gzip_header # Found gzip!
        if i == 0
          File.rename(file, dest) # Whole file is ok
        else # Use the file from this line on
          IO.copy_stream(file, dest, -1, file.pos - line.size)
        end
        return
      end
      break unless line.ascii_only? # Doesn't look like header lines
    end
    raise "sqldump didn't seem to give us gzip data"
  end

  def sqldump(dest, db_prefix = nil)
    wake
    cmd = ['sql-dump', '--gzip']
    if drush_version >= 7
      exclude = Exclude.clone
      exclude.gsub!(/(^|,)/, "\\1#{db_prefix}") if db_prefix
      cmd << '--structure-tables-list=' + exclude
    end

    # Write to a temp file, then rename it
    tmp = Tempfile.new(['.drush', File.extname(dest)], File.dirname(dest))
    drush(tmp, *cmd)
    gzfix(tmp, dest)
  end
end
end
