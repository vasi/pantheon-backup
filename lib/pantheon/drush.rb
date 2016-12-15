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
      ok = system(*cmd, :out => out)
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
    self[:drush_version] || drush('version', '--pipe').to_i
  end

  def sqldump(file, db_prefix = nil)
    wake
    cmd = ['sql-dump', '--gzip']
    if drush_version >= 7
      exclude = Exclude.clone
      exclude.gsub!(/(^|,)/, "\\1#{db_prefix}") if db_prefix
      cmd << '--structure-tables-list=' + exclude
    end

    # Write to a temp file, then rename it
    tmp = Tempfile.new(['drush', File.extname(file)], File.dirname(file))
    drush(tmp, *cmd)
    File.rename(tmp, file)
  end
end
end
