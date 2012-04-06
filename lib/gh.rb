require 'curb'
require 'json'
require 'ostruct'
require 'cgi'

class GH 
  attr_accessor :username, :password, :user, :repo, :token
  ISSUE_FILTERS = %W| labels assignee state milestone since per_page page |
 
  def initialize(config) 
    setup(config)
  end

  def token?
    return token 
  end

  def repo?
    return @user && @repo
  end

  def ready?
    return token && repo?
  end

  def repo_path
    repo? ? "#{@user}/#{@repo}" : nil  
  end

  def setup(config)
    @token = config[:token] 
    @user = config[:user] 
    @repo = config[:repo] 
  end

  def normalize_issue(hash)
    warn hash.inspect
    ret = OpenStruct.new(hash)
    ret.labels    = (hash['labels'] || []).collect { |l| normalize_label(l) }
    ret.milestone = normalize_milestone(hash['milestone'] || { :title => 'Others', :number => 0 })
    ret.assignee  = normalize_user(hash['assignee'])
    ret
  end

  def normalize_user(hash={ :name => '-na-' })
    return OpenStruct.new(hash)
  end

  def normalize_label(hash)
    return OpenStruct.new(hash)
  end

  def normalize_milestone(hash)
    return OpenStruct.new(hash)
  end

  def normalize_comment(hash)
    ret = OpenStruct.new(hash)
    ret.user = normalize_user(hash['user'])
    return ret
  end

  def comments(n)
    return request("issues/#{n}/comments").collect { |c| normalize_comment(c) }
  end

  def issues(incomming={})
    params = {}
    ISSUE_FILTERS.each { |k| params[k] = incomming[k] if incomming[k] && incomming[k] != '' }
    params['per_page'] ||= 100
    params['page'] ||= 1
    puts "calling page: #{params['page']}"

    query = params.keys.collect { |k| "#{k}=#{CGI.escape(params[k].to_s)}" }.join('&')

    ret = request("issues?#{query}").collect { |i| normalize_issue(i) }.sort { |a,b| a.number <=> b.number }

    if ret.any? && ret.length <= params['per_page']
      params['page'] += 1
      puts "Paging #{params['page']}, #{ret.length} | #{params['per_page']}"
      ret += issues(params) 
    end

    return ret
  end

  def issue(n)
    return normalize_issue(request("issues/#{n}"))
  end

  def post(path, params) 
    c = Curl::Easy.http_post(url(path), params.to_json) do |curl|
      curl.http_auth_types = :basic
      curl.username = username
      curl.password = password
      curl.headers = { 'Authorization' => "token #{token}" }
    end

    c.perform

    if c.response_code != 200
      raise "error accessing github api: #{url(path)} - #{c.body_str}"
    end

  end
 

  def milestones
    request("milestones").collect { |m| OpenStruct.new(m) }
  end

  def request(path)
    puts path
    c = Curl::Easy.new(url(path)) { |c| c.headers = { 'Authorization' => "token #{token}" } }

    c.perform
    if c.response_code != 200
      raise "error accessing github api: #{url(path)} - #{c.body_str}"
    end
    return JSON.parse(c.body_str)
  end

  def url(path)
    return "https://api.github.com/repos/#{repo_path}/#{path}"
  end

end

