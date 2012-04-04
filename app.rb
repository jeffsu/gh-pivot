require 'sinatra'
require 'haml'
require 'yaml'
require 'rack'

ROOT = File.dirname(__FILE__)
require "#{ROOT}/lib/gh"


class App < Sinatra::Application
  enable :sessions

  CONFIG = YAML.load_file("#{ROOT}/config.yml")
  @@gh = GH.new(CONFIG)

  get '/' do
    haml :index
  end

  post '/login' do
    @@gh.password = params[:password]
    redirect '/'
  end

  get '/pivot' do
    @gh = @@gh
    @labels = params[:group_by].to_s.split(',')
    @issues = @@gh.issues(params)
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

  get '/milestones' do
    @gh = @@gh
    @milestones = @@gh.milestones + [ OpenStruct.new({ :title => 'Others', :number => 0 }) ]
    @issues = @@gh.issues(params)

    @by_milestones = {}
    @issues.each { |i| (@by_milestones[i.milestone ? i.milestone.number : 0] ||= []) << i }

    haml :milestones
  end

  post '/update-issue' do
    issue = @@gh.issue(params[:number])
    
    if params[:label]
      labels = issue.labels.collect { |l| l.name }
      labels << params[:label]
      labels.reject! { |l| l == params[:remove] }
      @@gh.post("issues/#{issue.number}", :labels => labels)

    elsif params[:milestone]
      @@gh.post("issues/#{issue.number}", :milestone => params[:milestone] == '0' ? nil : params[:milestone])
    end
  end
end
