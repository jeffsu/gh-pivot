require 'sinatra'
require 'haml'
require 'yaml'

ROOT = File.dirname(__FILE__)
require "#{ROOT}/lib/gh"

CONFIG = YAML.load_file("#{ROOT}/config.yml")
@@gh = GH.new(CONFIG)

get '/' do
  haml :index
end

post '/login' do
  @@gh.username = params[:username]
  @@gh.password = params[:password]
  redirect '/'
end

get '/pivot' do
  @labels = params[:labels].split(',')
  @issues = @@gh.issues
  @by_labels = { 'others' => [] }
  @labels.each { |l| @by_labels[l] = [] }

  if filters = params[:filters]
    labels = filters.split(',')
    @issues.select! { |i| i.labels.any? { |l| labels.include?(l['name']) } } if labels.any?
  end

  @issues.each do |i| 
    if l = i.labels.find { |l| @labels.include?(l['name']) }
      @by_labels[l['name']] << i
    else
      @by_labels['others'] << i
    end
  end

  @by_labels.values { |v| v.sort! { |a,b| a.number <=> b.number } }

  haml :pivot
end

get '/milestones' do
  @milestones = @@gh.milestones + [ OpenStruct.new({ :title => 'Others', :number => 0 }) ]
  @issues = @@gh.issues

  @by_milestones = {}
  @issues.each { |i| (@by_milestones[i.milestone ? i.milestone['number'] : 0] ||= []) << i }
  puts @by_milestones.inspect

  haml :milestones
end

post '/update-issue' do
  issue = @@gh.issue(params[:number])
  
  if params[:label]
    labels = issue.labels.collect { |l| l['name'] }
    labels << params[:label]
    labels.reject! { |l| l == params[:remove] }
    @@gh.post("issues/#{issue.number}", :labels => labels)

  elsif params[:milestone]
    @@gh.post("issues/#{issue.number}", :milestone => params[:milestone] == '0' ? nil : params[:milestone])
  end
end
