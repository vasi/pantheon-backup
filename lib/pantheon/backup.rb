require 'logrotate'
require 'pathname'
require 'threadpool'
require 'yaml'

class Pantheon
class Backup
  Threads = 8
  Current = 'drupal.sql.gz'
  FilePat = 'drupal-%F-%R.sql.gz'

  def initialize(conffile, logger)
    @conf = YAML.load_file(conffile)
    @logger = logger

    @pantheon = Pantheon.new(IO.read(@conf['token']))
    @pantheon.sshkey = @conf['sshkey']
    @dest = Pathname.new(@conf['destination'])
    @pool = Threadpool.new(Threads, logger)
  end

  def directory(sitename)
    conf = @conf['sites'][sitename] || {}
    dir = conf['directory'] || sitename
    @dest + dir + 'pantheon'
  end

  def backup_env(env, conf)
    dir = directory(env.site.name) + env.name
    dir.mkpath
    file = dir + Date.today.strftime(FilePat)
    @logger.info('Backing up ' + env.fullname)
    env.sqldump(file.to_s, conf['prefix'])
  end

  def backup_site(site, conf)
    site.environments.select(&:can_backup?).each do |env|
      @pool.run { backup_env(env, conf) }
    end
  end

  def backup
    @pantheon.sites.select(&:can_backup?).each do |site|
      conf = @conf['sites'][site.name] || {}
      @pool.run { backup_site(site, conf) }
    end
    @pool.wait
    @logger.info('Rotating backups')
    rotate
  end

  def rotate
    @pantheon.sites.each do |site|
      dir = directory(site.name)
      next unless dir.exist?
      dir.children.each do |env|
        rotate = Logrotate.new(env, Current, FilePat, @conf['expiry']['base'],
          @conf['expiry']['backoff'])
        rotate.rotate
      end
    end
  end
end
end

