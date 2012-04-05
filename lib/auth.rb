require 'oauth2'
require 'yaml'

class Auth
  CONFIG = YAML.load_file(File.dirname(__FILE__) + '/../config.yml')

  class << self
    def client
      @client ||= OAuth2::Client.new(CONFIG['client_id'], CONFIG['secret'],
                         :ssl => {:ca_file => CONFIG['cert'] },
                         :site => 'https://api.github.com',
                         :authorize_url => 'https://github.com/login/oauth/authorize',
                         :token_url => 'https://github.com/login/oauth/access_token')
    end

    def redirect_uri(url, path = '/callback', query = nil)
      uri = URI.parse(url)
      uri.path  = path
      uri.query = query
      uri.to_s
    end
  end

end
