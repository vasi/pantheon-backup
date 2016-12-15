require 'ostruct'

class Pantheon
# An environment: live, dev, multi-env, etc
class Environment < OpenStruct
  Exclude = 'cache*,watchdog,sessions,search_*,flood,semaphore,accesslog'

  attr_accessor :site

  def initialize(pantheon, site, name, h)
    super(h)
    self.name = name
    @site = site
    @pantheon = pantheon
  end

  def fullname
    "#{site.name}.#{name}"
  end

  # Must be provisioned
  def can_backup?
    self.target_commit
  end

  def hostname
    data = @pantheon.request("sites/#{site.id}/environments/#{name}/hostnames")
    data.last['id']
  end

  def wake
    @pantheon.request("http://#{hostname}/pantheon_healthcheck")
  end
end
end

require 'pantheon/drush'
