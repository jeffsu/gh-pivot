require 'curb'
require 'json'
require 'ostruct'

class GH 
  attr_accessor :username, :password, :user, :repo
 
  def initialize(credentials) 
    @username = credentials['username'] 
    @password = credentials['password'] 

    @user = credentials['user'] 
    @repo = credentials['repo'] 

    @requests = nil
  end

  def issues(params={})
    query = params.keys.collect { |k| "#{k}=#{params[k]}" }.join('&')
    return request("issues?#{query}").collect { |i| OpenStruct.new(i) }.sort { |a,b| a.number <=> b.number }
  end

  def issue(n)
    return OpenStruct.new(request("issues/#{n}"))
  end

  def post(path, params) 
    puts params.to_json
    c = Curl::Easy.http_post(url(path), params.to_json) do |curl|
      curl.http_auth_types = :basic
      curl.username = username
      curl.password = password
    end
  end
 

  def milestones
    request("milestones").collect { |m| OpenStruct.new(m) }
  end

  def request(path)
    c = Curl::Easy.new(url(path))

    c.http_auth_types = :basic
    c.username = username
    c.password = password

    c.perform
    return JSON.parse(c.body_str)
  end

  def url(path)
    return "https://api.github.com/repos/#{user}/#{repo}/#{path}"
  end


  def multi
    m = Multi.new(self)
    yield(m) 
    return m.execute
  end

  class Multi
    def initialize(gh) 
      @gh   = gh
      @ret  = Hash.new
      @m = Curl::Multi.new 
    end

    def issues(key=:issues, params={})
      query = params.keys.collect { |k| "#{k}=#{params[k]}" }.join('&')
      request(key, "issues?#{query}")
    end

    def execute
      @m.perform { }
      return @ret
    end

    def request(key, path)
      c = Curl::Easy.new("https://api.github.com/repos/#{@gh.user}/#{@gh.repo}/#{path}")
      puts("https://api.github.com/repos/#{@gh.user}/#{@gh.repo}/#{path}")

      c.http_auth_types = :basic
      c.username = @gh.username
      c.password = @gh.password

      c.on_body { |data| @ret[key] = data; puts data }
      @m.add(c)
    end

  end
end

