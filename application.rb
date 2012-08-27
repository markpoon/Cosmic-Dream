# Requirements
require "sinatra"
require "haml"
require "sass"
require "redcarpet"
require "pry"
require "mongoid"
require "coffee-script"
require "geocoder"
require "braintree"

enable :inline_templates
set :public_folder, 'public'
Mongoid.load! "config/mongoid.yml"
enable :sessions

#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# MODELS #
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
class User
  include Mongoid::Document
  field :email, type: String
  field :salt, type: String
  field :hashed_password, type: String
  field :coordinates, type: Array
  field :address
  include Geocoder::Model::Mongoid
  reverse_geocoded_by :coordinates
  after_validation :reverse_geocode
  
  def password=(pass)
    @password = pass
    self.salt = User.random_string(10) unless self.salt
    self.hashed_password = User.encrypt(@password, self.salt)
  end

  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass + salt)
  end

  def self.authenticate(email, pass)
    u = User.find_by(email: email)
    return nil if u.nil?
    return u if User.encrypt(pass, u.salt) == u.hashed_password
    nil
  end

  def self.random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    str = ""
    1.upto(len) { |i| str << chars[rand(chars.size-1)] }
    return str
  end  
  
  
  field :spirit, type: Integer, default: 8
  field :avatar, type: Moped::BSON::ObjectId

  has_many :characters
  has_many :locations
end
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
class Npc
  include Mongoid::Document
  field :name, type: String 
  field :xp, type: Integer
  
  field :strength, type: Integer, default: 8
  field :constitution, type: Integer, default: 8
  field :dexterity, type: Integer, default: 8
  field :extroversion, type: Integer, default: 8
  field :introvert, type: Integer, default: 8
  field :intellegence, type: Integer, default: 8
  field :resolve, type: Integer, default: 8
  field :intuition, type: Integer, default: 8
  
  field :status, type: Array, default: [:disoriented]
  
  field :health, type: Array, default: [8, 5, 3] # scratch / wound / fatal
  field :healthmax, type: Array, default: [8, 5, 3]
  
  field :mana, type: Integer, default: 1
  field :manamax, type: Integer, default: 1
  
  field :energy, type: Array, default: [0,0,0]
  
  field :ability, type: Hash, default: {}

  field :action, type: Integer, default: 1
  field :move, type: Integer, default: 1
  field :interrupt, type: Integer, default: 1

  field :story, type: Hash, default: {}  

  has_many :items
  belongs_to :location
end
class Character < Npc
  include Mongoid::Document
  belongs_to :user
  has_many :journeys
end
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
class Journey
  include Mongoid::Document
  field :destiny, type: Symbol
  embeds_many :stories
end 
class Story
  include Mongoid::Document
  field :step, type: Array
  field :theme, type: Array
  field :antagonist, type: Array
  field :nemesis, type: Moped::BSON::ObjectId
end
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
class Item
  include Mongoid::Document
  belongs_to :user
  field :name, type: Symbol
  field :material, type: Symbol 
  field :size, type: Integer
  field :quality, type: Integer
  
  field :improvement, type: Hash
  
  field :equiped, type: Boolean
  field :equipedlocation, type: Symbol
  
  field :charge, type: Integer
  field :durability, type: Integer
  
  def self.chargemax
    l = self.durability
    if self.material == :wood || :leather
      l *= 2
    else
      l *= 0.7
    end
    if self.equipedlocation == :finger || :neck || :head
      l *= 1.5
    else
      l *= 0.7
    end
    l.round
  end
  
  def self.durabilitymax
    l = self.size * 3.14 + quality / 1.618 - improvements * 0.7
    if self.material == :iron
      l *= 2
    elsif self.material == :steel
      l *= 3.14
    else
      durablitylimit *= 0.7
    end
    if self.equipedlocation == :lefthand || :righthand || :leftrighthand
      l *= 1.618
    else
      l *= 0.7
    end
    l.round
  end
end
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
class Location
  include Mongoid::Document  
  field :coordinates, type: Array, default: []
  field :terrain, type: Symbol
  field :structures, type: Hash

  has_many :npcs
end
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

helpers do
  def admin? ; request.cookies[settings.username] == settings.token ; end
  def protected! ; halt [ 401, 'Not Found' ] unless admin? ; end
  def search(pattern="")
    stringarray = pattern.strip.gsub(/(\^\s\*|\d)/, "").downcase.gsub(/\s+/, " ").split(", ")
    stringarray.map!{|s| Regexp.new(s, true)}
    Npc.or({:content.in => stringarray}, {:field.in => stringarray})
  end
  def random(min = 0, max = 0)
    min + (rand max-min)
  end
end

#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# ROUTES #
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# SESSIONS #
get '/login' do
  haml :login
end

post '/login' do
  (params['username']==settings.username&&params['password']==settings.password) ? (response.set_cookie(settings.username,settings.token); redirect '/') : (redirect "/")
end

get '/logout' do
  response.set_cookie(settings.username, false); redirect '/'
end

put '/user/:id' do
  user = User.where(_id: params[:_id])
  if params[:location] = !user.location.last
    user.location.push params[:location] 
  end
end

# REST #
get '/location/' do
  # list all
  @location = Location.near(params[:coordinates])
  redirect '/' unless request.xhr?
end

get '/location/:id' do
  location = Location.find_by(url: params[:coordinates])
  if location nil? then
    raise Sinatra::NotFound
  else
    status 200
    body(location.to_json)
  end
end

put '/location/' do
  data = JSON.parse(request.body.string)
  if data.nil? or !data.has_key? 'content' then
    status 404
  else
    data.each do |d|
      location = Location.new( # mongofield: object[:key] remember the comma but not for the last field
        content: d[:terrain],
        created: d[:npc],
        updated: d[:structures]
        ) 
      location.save
    end
    status 200
  end
end

put '/location/:id' do
  data = JSON.parse(request.body.string)
  if data.nil? or !data.has_key? 'content' then
    status 404
  else
    location = Location.new( #~#~#~ add stuff here! remember the comma
      content: data[:terrain],
      created: data[:npc],
      updated: data[:structures]
    ) 
    location.save
    status 200
  end
end

post '/location/:id' do
  data = JSON.parse(request.body.string)
  if data.nil? then
    status 404
  else
    location = Location.get(params[:id])
    if location.nil? then
      status 404
    else
      updated = false
      %w().each do |k| #~#~#~ You need to put what fields to update
        if data.has_key? k
          location[k] = data[k]
          updated = true
        end
      end
      if updated then
        location[:modified] = Time.now
        !location.save ? (status 500) : (status 200)
      end
    end
  end
end

delete '/location/' do
  #delete all
  status 200 unless admin?
end

delete '/location/:id' do
  location = Location.get(params[:id])
  if location nil? then
    status 404
  else
    location.destroy ? (status 200) : (status 500)
  end
end

get '/npc/' do
  # list all
  npc = Npc.all
end

get '/npc/:id' do
  npc = Npc.find_by(url: params[:id])
  if npc nil? then
    raise Sinatra::NotFound
  else
    status 200
    body(npc.to_json)
  end
end

put '/npc/' do
  #bulk update
end

put '/npc/:id' do
  data = JSON.parse(request.body.string)
  if data.nil? or !data.has_key? 'content' then
    status 404
  else
    npc = Npc.new( #~#~#~ add stuff here! remember the comma
      content: data[:content],
      created: data[:created],
      updated: data[:updated]
    ) 
    npc.save
    status 200
  end
end

post '/npc/:id' do
  data = JSON.parse(request.body.string)
  if data.nil? then
    status 404
  else
    npc = Npc.get(params[:id])
    if npc.nil? then
      status 404
    else
      updated = false
      %w().each do |k| #~#~#~ You need to put what fields to update
        if data.has_key? k
          npc[k] = data[k]
          updated = true
        end
      end
      if updated then
        npc[:modified] = Time.now
        !npc.save ? (status 500) : (status 200)
      end
    end
  end
end

delete '/npc/' do
  #delete all
  status 200 unless admin?
end

delete '/npc/:id' do
  npc = Npc.get(params[:id])
  if npc nil? then
    status 404
  else
    npc.destroy ? (status 200) : (status 500)
  end
end

get "/style.css" do
  content_type 'text/css', :charset => 'utf-8'
  scss :style
end

get "/script.js" do
  content_type "text/javascript", :charset => 'utf-8'
  coffee :script
end

get "/?" do
  haml :index
end

not_found{haml :'404'}
error{@error = request.env['sinatra_error']; haml :'500'}

__END__

@@layout
!!! 5
%html
  %head
    %title= @title
    %meta{name: "description", content: @description}
    %meta{name: "viewport", content: "width=device-width, minimum-scale=1.0, maximum-scale=2.0"}
    %link{href: "/css/normalize.css", rel: "stylesheet"}
    %link{href: "/style.css", rel: "stylesheet"}
    %script{src: "/js/modernizr.js"}
  %body
    %header
  %div#container
    = yield
  %footer
  %script{src: "/js/lovely/core-1.1.0.js", type: "text/javascript"}
  %script{src: "/js/underscore-min.js", type: "text/javascript"}
  %script{src: "/js/crafty-min.js", type: "text/javascript"}
  %script{src: "/script.js"}
  
@@index
%span#longitude
%span#latitude

@@404
.warning
  %h1 404
  %hr 
  Apologies, there were no results found for your query.
  %hr
  
@@500
.warning
  %h1 500
  %hr
  %p @error.message
  %hr
