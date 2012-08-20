# Requirements
[ "sinatra", "haml", "sass", "redcarpet", "pry", "mongoid", "coffee-script", "geocoder", "braintree" ].each { |gem| require gem}
enable :inline_templates
set :public_folder, 'public'
Mongoid.load! "config/mongoid.yml"
enable :sessions

#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# MODEL #
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

class User
  include Mongoid::Document
  field :email, type: String
  field :salt, type: String
  field :hashed_password, type: String
  
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
  
  field :coordinates, type: Array, default: []
  field :address 
 
end

#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

class Character
  include Mongoid::Document
  field :name, type: String 
  field :content, type: String 
  field :updated, type: DateTime, default: nil
  field :created, type: DateTime, default: Time.now
end

#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

class Location
  include Mongoid::Document
  
  field :coordinates, type: Array, default: []
  field :address
  
  field :terrain, type: Symbol

#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#

end

helpers do
  # SESSIONS #  
  def admin? ; request.cookies[settings.username] == settings.token ; end
  def protected! ; halt [ 401, 'Not Found' ] unless admin? ; end
  def search(pattern="")
    stringarray = pattern.strip.gsub(/(\^\s\*|\d)/, "").downcase.gsub(/\s+/, " ").split(", ")
    stringarray.map!{|s| Regexp.new(s, true)}
    Character.or({:content.in => stringarray}, {:field.in => stringarray})
  end
end

#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# ROUTE #
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
get '/character/' do
  # list all
  character = Character.all
end

get '/character/:id' do
  character = Character.find_by(url: params[:id])
  if character nil? then
    raise Sinatra::NotFound
  else
    status 200
    body(character.to_json)
  end
end

put '/character/' do
  #bulk update
end

put '/character/:id' do
  data = JSON.parse(request.body.string)
  if data.nil? or !data.has_key? 'content' then
    status 404
  else
    character = Character.new( #~#~#~ add stuff here! remember the comma
      content: data[:content],
      created: data[:created],
      updated: data[:updated]
    ) 
    character.save
    status 200
  end
end

post '/character/:id' do
  data = JSON.parse(request.body.string)
  if data.nil? then
    status 404
  else
    character = Character.get(params[:id])
    if character.nil? then
      status 404
    else
      updated = false
      %w().each do |k| #~#~#~ You need to put what fields to update
        if data.has_key? k
          character[k] = data[k]
          updated = true
        end
      end
      if updated then
        character[:modified] = Time.now
        !character.save ? (status 500) : (status 200)
      end
    end
  end
end

delete '/character/' do
  #delete all
  status 200 unless admin?
end

delete '/character/:id' do
  character = Character.get(params[:id])
  if character nil? then
    status 404
  else
    character.destroy ? (status 200) : (status 500)
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
