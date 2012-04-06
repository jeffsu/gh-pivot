require 'sinatra'
require 'haml'
require 'yaml'
require 'rack'
require 'cgi'

ROOT = File.dirname(__FILE__)
require "#{ROOT}/lib/gh"
require "#{ROOT}/lib/auth"

class App < Sinatra::Application
  enable :sessions

  set :haml, { :escape_html => true }
  before do
    @gh = GH.new(session)

    return if request.path == '/callback'

    if !@gh.token? && request.path != '/login' && request.path != '/'
      redirect '/'
    end


    if request.path.match(/^\/repos/)
      splitted = request.path.split('/')
      @gh.user = splitted[2]
      @gh.repo = splitted[3]
    end


    if !@gh
      haml :login
    elsif @gh.repo && @gh.user
      haml :index
    end

  end

  helpers do
    def h(str)
      str
    end

    def prefix
      if @gh.ready?
        "/repos/#{@gh.user}/#{@gh.repo}"
      else 
        ""
      end
    end
  end

  post '/login' do
    session[:username] = params[:username]
    session[:password] = params[:password]
    session[:repo]     = params[:repo]
    session[:user]     = params[:user] || params[:username]
    @gh = GH.new(session)
    haml :index
  end

  get '/' do
    if params[:repo] && params[:user]
      redirect "/repos/#{params[:user]}/#{params[:repo]}/pivot"
    else
      haml :index
    end
  end


  get '/repos/:user/:repo/pivot' do
    @labels = params[:group_by].to_s.split(',')
    @issues = @gh.issues(params)
    @by_labels = { 'others' => [] }
    @labels.each { |l| @by_labels[l] = [] }

    @issues.each do |i| 
      if i.labels && l = i.labels.find { |l| @labels.include?(l.name) }
        @by_labels[l.name] << i
      else
        @by_labels['others'] << i
      end
    end

    @by_labels.values { |v| v.sort! { |a,b| a.number <=> b.number } }

    haml :pivot
  end

  get '/repos/:user/:repo/milestones' do
    @milestones = @gh.milestones + [ OpenStruct.new({ :title => 'Others', :number => 0 }) ]
    @issues = @gh.issues(params)

    @by_milestones = {}
    @issues.each { |i| (@by_milestones[i.milestone ? i.milestone.number : 0] ||= []) << i }

    haml :milestones
  end

  post '/repos/:user/:repo/update-issue' do
    issue = @gh.issue(params[:number])
    
    if params[:label]
      labels = issue.labels.collect { |l| l.name }
      labels << params[:label]
      labels.reject! { |l| l == params[:remove] }
      @gh.post("issues/#{issue.number}", :labels => labels)

    elsif params[:milestone]
      @gh.post("issues/#{issue.number}", :milestone => params[:milestone] == '0' ? nil : params[:milestone])
    end
  end

  get '/repos/:user/:repo/issues/:n' do
    @issue = @gh.issue(params[:n])
    @issue.comments =  @issue.comments > 0 ? @gh.comments(@issue.number) : []
    haml :issue
  end

  get '/login' do
    url = Auth.client.auth_code.authorize_url(:redirect_uri => Auth.redirect_uri(request.url), :scope => 'repo')
    puts "Redirecting to URL: #{url.inspect}"
    redirect url
  end

  get '/logout' do
    session[:token] = nil
    session[:login] = nil
    redirect '/'
  end


    
  get '/callback' do
    begin
      access_token = Auth.client.auth_code.get_token(params[:code], :redirect_uri => Auth.redirect_uri(request.url))
      session[:token] = access_token.token
      session[:login] = JSON.parse(access_token.get('/user').body)['login']
      puts session[:token]
      redirect '/'
    rescue OAuth2::Error => e
      %(<p>Outdated ?code=#{params[:code]}:</p><p>#{$!}</p><p><a href="/auth/github">Retry</a></p>)
    end
  end

  get '/*' do
    redirect '/'
  end
end
