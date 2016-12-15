require 'ostruct'

class Pantheon
class Site < OpenStruct
  def initialize(pantheon, h)
    super(h.merge(h.delete('site')))
    @pantheon = pantheon
  end

  # Must be a live Drupal site
  def can_backup?
    /^drupal/.match(framework) && !frozen
  end

  def environments
    @pantheon.request("sites/#{id}/environments").map do |name, h|
      Environment.new(@pantheon, self, name, h)
    end
  end
end
end
