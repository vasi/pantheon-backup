require 'json'
require 'net/http'

class Pantheon
  attr_accessor :sshkey

  def initialize(token)
    @token = token
    @http = {}
  end

  def request(uri, post = nil)
    resp = nil
    10.times do # Follow redirects
      base = 'https://terminus.pantheon.io/api/'
      # Ok to specify an absolute URL, we won't use our base
      uri = base + uri unless /^http/.match(uri)
      uri = URI(uri)

      # If it's a post, add the data
      req = (post ? Net::HTTP::Post : Net::HTTP::Get).new(uri.request_uri)
      req['User-Agent'] = 'Terminus' # Required by Pantheon
      if post
        req['Content-Type'] = 'application/json'
        req.body = JSON.dump(post)
      end

      # Use our authentication, if we have any
      @auth.each { |k, v| req[k] = v } if defined? @auth

      resp = Net::HTTP.start(uri.host, uri.port,
          :use_ssl => uri.scheme == 'https') do |http|
        http.request(req)
      end

      break unless Net::HTTPRedirection === resp
      uri = resp['location']
    end

    resp.value # raise on error
    return JSON.parse(resp.body) if resp.content_type == 'application/json'
    resp.body
  end

  # Authenticate with Pantheon
  def auth
    return @auth if defined? @auth
    data = request('authorize/machine-token', {
      'machine_token' => @token,
      'client' => 'terminus',
    })
    @user = data['user_id']
    @auth = { 'Authorization' => 'Bearer ' + data['session'] }
  end

  # Get all accessible sites
  def sites
    auth
    request("users/#@user/memberships/sites").map { |h| Site.new(self, h) }
  end

  def self.backup(config, logger)
    Backup.new(config, logger).backup
  end
end

require 'pantheon/backup'
require 'pantheon/site'
require 'pantheon/environment'
