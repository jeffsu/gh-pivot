require 'curb'
require 'json'
require 'ostruct'

class GH 
  attr_accessor :username, :password, :user, :repo
  ISSUE_FILTERS = %W| labels assignee state milestone since per_page page |
 
  def initialize(credentials) 
    @username = credentials[:username] 
    @password = credentials[:password] 

    @user = credentials[:user] 
    @repo = credentials[:repo] 
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

    query = params.keys.collect { |k| "#{k}=#{params[k]}" }.join('&')

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
    end

    puts c.body_str
  end
 

  def milestones
    request("milestones").collect { |m| OpenStruct.new(m) }
  end

  def request(path)
    puts path
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

end

