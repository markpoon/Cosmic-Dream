# Requirements
require "sinatra"
require "haml"
require "sass"
require "redcarpet"
require "pry"
require "json"
require "active_support/core_ext/hash/conversions"
require "mongoid"
require "coffee-script"

require "net/http"
require "uri"

enable :inline_templates
set :public_folder, 'public'
Mongoid.load! "config/mongoid.yml"
enable :sessions

#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
helpers do
  def authorized?; session[:user] ? (return true) : (status 403); end
  def authorize!; redirect '/login' unless authorized?; end  
  def logout!; session[:user] = false; end
  def search(pattern="")
    stringarray = pattern.strip.gsub(/(\^\s\*|\d)/, "").downcase.gsub(/\s+/, " ").split(", ")
    stringarray.map!{|s| Regexp.new(s, true)}
    Character.or({:content.in => stringarray}, {:field.in => stringarray})
  end
  def selectsector(c)
    sectors = []
    (c[0] - 0.01..c[0] + 0.01).step(0.01) do |i|
      (c[1] - 0.01..c[1] + 0.01).step(0.01) do |j|
         sectors.push [i, j].map{|k|k.round 2}
      end
    end
    sectors
  end
end
module CharUtility
  def random(min = 0, max = 0); min + (rand max-min); end
  def randomname(g = :m)
    if g  == :m
      [:John, :Jack, :Jason, :Aaron, :Cole, :Drew, :Edward, :Frank, :Greg, :Hank, :Issac, :James, :Kevin, :Leon, :Mark, :Oliver, :Ted, :Ryan, :Sean, :Victor, :Wes].sample
    elsif g == :f
      [:Alice, :Brenda, :Cathy, :Denise, :Ella, :Frey, :Gina, :Helen, :Isabelle, :Julie, :Karen, :Lily, :Margaret, :Tina].sample
    end
  end
  def stat; [:strength, :stamina, :dexterity, :intellegence, :intuition, :resolve, :persuasion]; end
  def alignment(s)
    mod = case s
      when :strength then [[:arrogance, :stamina, :arrogance, :stubbornness], [:intuition, :caution, :intellegence, :nil]]
      when :stamina then [[:resolve, :stubbornness],[:caution, nil]]
      when :dexterity then [[:intellegence, :caution, :indifference],[:strength, :stamina]]
      when :intellegence then [[:greed, :arrogance],[:strength, :resolve, :intuition]]
      when :intuition then [[:persuasion, :resolve],[:caution, :stubbornness, :intellegence]]
      when :resolve then [[:stubbornness, :caution, :arrogance, :intuition],[:intellegence, :persuasion, nil ]]
      when :persuasion then [[:arrogance, :intellegence, :intuition],[:caution, :indifference]]
      else nil
    end
    return mod
  end
end
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
# MODELS #
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include CharUtility
  field :email, type: String
  field :salt, type: String
  field :hashed_password, type: String
  field :coordinates, type: Array
  field :spirit, type: Integer, default: 8
  field :vision, type: Integer, default: 6
  has_many :characters, dependent: :nullify
  belongs_to :location
  field :avatar, type: Moped::BSON::ObjectId
  
  def package
    u  = self.as_json
    ["location_id", "_id", "created_at", "updated_at", "salt", "hashed_password", "Location"].each do |k|
      u.delete(k)
    end
    u["coordinates"] = self.location.coordinates
    u
  end
    
  after_create do |u|
    g = [:m, :f][rand(2)]
    n = randomname g
    u.save
    u.characters.create name: n, gender: g, location_id: u.location_id
    puts "User [#{u.id}] created at coordinates: #{u.location_id}"  
  end
   
  def password=(pass)
    @password = pass
    self.salt = User.random_string(10) unless self.salt
    self.hashed_password = User.encrypt(@password, self.salt)
  end

  def self.authenticate(email, pass)
    u = User.find_by(email: email)
    return nil if u.nil?
    return u if User.encrypt(pass, u.salt) == u.hashed_password
    nil
  end

  protected
  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass + salt)
  end
  def self.random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    str = ""
    1.upto(len) { |i| str << chars[rand(chars.size-1)] }
    return str
  end
end
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
class Character
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include CharUtility
  belongs_to :user
  belongs_to :location

  field :name, type: String
  field :portrait, type: String # String for image url
  field :gender, type: Symbol   # m / f
  field :age, type: Integer
  field :vision, type: Integer, default: 1
  
  has_many :journeys, dependent: :delete
  field :xp, type: Integer
  field :status, type: Hash, default: {} # statusstring - enddatetime, effectstring - statstring, integer
  field :home, type: Moped::BSON::ObjectId
  
  field :abilities, type: Hash, default: {}
  has_many :items
  field :carry, type: Integer
  
  field :strength, type: Integer, default: rand(5..15)
  field :stamina, type: Integer, default: rand(5..15)
  field :dexterity, type: Integer, default: rand(5..15)
  field :persuasion, type: Integer, default: rand(5..15)
  field :intellegence, type: Integer, default: rand(5..15)
  field :intuition, type: Integer, default: rand(5..15)
  field :resolve, type: Integer, default: rand(5..15)

  field :indifference, type: Integer, default: rand(-15..15) # :curiosity, likely to open or play with things vs. not wanting to interact at all.
  field :materialism, type: Integer, default: rand(-15..15) # :idealism, actions that will be for physical things, gold, items, property  
  field :greed, type: Integer, default: rand(-15..15) # :naivity, actions that will benefit themselves vs. ones that will benefit the most people.
  field :caution, type: Integer, default: rand(-15..15) # :spontanaity, How likely a character will choose safe vs. unsafe actions.
  field :stubbornness, type: Integer, default: rand(-15..15) # :indecisive, stick to previous actions despite negative progress, likelihood to change actions
  field :arrogance, type: Integer, default: rand(-15..15) # :passive, attempts to take :rep vs. give more :rep to others

  field :gold, type: Integer, default: 0
  field :reputation, type: Integer, default: 0

  after_create do |c|
    c.age = rand(12..26)
    if !c.items.exists? 
      case c.age
        when 12..15 then
          c.items
          random(2, 4).times{c.items.create()}
        when 16..21 then
          c.gold += random(10, 25)
          random(4, 6).times{c.items.create()}
        when 22..26 then
          c.gold += random(75, 175)
          random(5, 7).times{c.items.create()}
        else nil
      end
    end
    c.portrait = ["./images/portrait.jpg", "./images/portrait2.jpg", "./images/portrait3.jpg"][rand(3)]
    c.carry = c.strength / 4 + 8
    c.xp = rand(20..50)
    c.save
    c.journeys.create
    puts "Character #{c.name}[#{c.id}] Created, Placed at #{c.location.coordinates}"
  end

  def package
    c  = self.as_json
    ["user_id", "location_id", "created_at", "updated_at"].each do |k|
      c.delete(k)
    end
    c["coordinates"] = self.location.coordinates
    c["scratchmax"] = self.scratchmax
    c["woundmax"] = self.woundmax
    c["manamax"] = self.manamax
    c["items"] = []
    self.items.each{|i| c["items"].push i.package}
    c
  end

  field :scratch, type: Integer, default: 0
  def scratchmax                                           # recovers at rate of 1/turn 
    (self.resolve + self.dexterity * 1.618).round
  end
  field :wound, type: Integer, default: 0
  def woundmax                                             # recovers at rate of 1/100 hrs, 5% chance that a wound point that recovers turns into a injury.
    ((self.stamina * 3 + self.resolve) - self.injury * 1.618).round
  end
  field :injury, type: Integer, default: 0                 # points are gained when healing wounds

  field :mana, type: Integer, default: 1
  def manamax 
    (self.intellegence * 3.14 + self.resolve * 1.618).round
  end

  protected
  def imbueSpirit(s)
    while c.spirit > 1  
      if c.spirit > 25 and rand(10) > 7
        c.ability.merge newability(:gen)
        c.spirit -= random(20, 25)
      else
        s -= random(1, 4)
        if c.spirit > 0
          self.statup(stat().sample)
        else break; end
      end
    end
  end

  private
  def statup=(stat)
    #self.send(up, += 1)
    stat = alignment(stat).map{|i|i.sample}
    self.up[0] += rand(2)
    self.up[1] -= rand(2)
  end
end
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
class Journey
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  belongs_to :character
  embeds_many :chapters
  field :hook, type: Symbol
  field :progress, type: Symbol
  field :plot, type: Symbol
  field :nemesis, type: Moped::BSON::ObjectId
  field :cast, type: Hash

  after_create do |j|
    plan(j)
    j.hook = [:dyingDelivery, :grimNecessity, :offense, :mistakenId, :mysteryChar, :oldFriend, :oldEnemy].sample
    j.plot = [:rising, :discovered, :intrigue, :invasion, :magicEnds, :founding, :ending, :destroyItem, :killNemesis].sample
    j.nemesis = [:spy, :avenger, :conquerer, :corruptor, :destroyer, :organizer, :zealot, :sufferer, :dragon].sample
    j.save
    j.chapters.create()
    puts "A Journey about a #{j.plot} started when a #{j.hook}  for #{j.character.name}[#{j.character.id}]."
    puts "Has Chapters: #{j.chapters}"
  end
  def plan(j)
    j.progress = case j.chapters.length
      when 0...3 
        (j.progress == :initiation or rand(3) == 1) ?  (j.progress = :departure) :  (j.progress = :initiation)
      when 4...9 then j.progress = :initiation
      when 10...15
        (j.progress == :returning or rand(5) == 4) ? (j.progress = :returning) : (j.progress = :initiation)
      else j.progress = :returning
    end
  end
  def self.theme=(length)
    self.theme = [:Espionage, :Horror, :Mystery, :War].sample
  end
end
class Chapter
  include Mongoid::Document
  include Mongoid::Timestamps
  embedded_in :journey
  field :progress, type: Symbol
  field :scenario, type: Array, default: []
  field :complete, type: Boolean, default: false
    
  field :twist, type: Array, default: []
  field :mystery, type: Array, default: []
  field :antagonist, type: Array, default: []
  field :dungeon, type: Array, default: []
  field :reward, type: Array, default: []

  after_create do |c|
    c.progress = c.genProgress
    c.scenario = c.genScenario
    c.twist =  c.genTwist rand(2) + 1
    c.mystery =  c.genMystery
    c.antagonist =  c.genAntagonist rand(4) + 3
    c.reward =  c.genReward rand(3) + 1
    c.save
    puts "a chapter written about #{c.journey.character.name}:"
    p c
  end

  def genProgress(p = :departure)
    if p == :departure
      [:call, :refuse, :aid, :threshold, :metamorphosis].sample
    elsif p == :initiation
      [:trials, :meeting, :vision, :temptation, :descent, :atonement, :apotheosis, :boon].sample
    elsif p == :returning
      [:refuse, :flight, :rescue, :threshold, :master, :freedom].sample
    end
  end
  def genScenario(n = 1)
    [:capturetheflag, :subdue, :stop, :destroy, :ambushed, :ambushing, :escort, :mayhem, :retrieve, :deliver, :protect, :holdposition, :sabatoge, :rescue, :escape, :survive, :chase].sample(n)
    
  end
  def genTwist(n = 1)
    [:doubleagent, :misdirection, :trap, :dilemma, :wards, :guarded, :seperate, :duel].sample(n)
  end
  def genMystery(n = 1)
    [:telecircle, :gate, :runes].sample(n)
  end
  def genAntagonist(n = 1)
    [:warrior, :fighter, :bowmen, :thief, :healer, :mage].sample(n)
  end
  def genReward(n = 1)
    [:clue, :gold, :armor, :weapons, :magic, :tools, :material, :key].sample(n)
  end

end
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
class Item
  include CharUtility
  include Mongoid::Document
  belongs_to :character
  belongs_to :place
  field :portrait, type: Array, default: [0,0]
  field :name, type: Symbol
  field :material, type: Symbol
  field :quality, type: Integer
  field :effect, type: Hash
  
  field :equiped, type: Boolean, default: false
  field :equipedlocation, type: Symbol
  
  field :charge, type: Integer
  field :durability, type: Integer
  
  after_create do |i|
    i.quality  = random(1, 10)
    i.durability = random(10, 20)
    if random(1, 100) <= 10
      i.material =[:gold, :silver].sample
      i.quality+10
      i.durability-5
    else
      i.material = [:wood, :leather, :iron, :steel].sample
      i.quality - 5
      i.durability + 12
    end
    i.equipedlocation = case i.material
      when :wood then [:twohand,:hand,:handshield].sample
      when :leather then [:body,:feet,:head,:neck].sample
      when :iron then [:twohand,:hand,:handshield,:body,:head].sample
      when :steel then [:twohand,:hand,:handshield,:body,:head].sample
      when :silver then [:neck,:finger,:twohand,:hand,:body,:head,:neck].sample
      when :gold then [:neck,:finger,:head].sample
    end
    d = i.quality / 20 + 1
    d > 7 ? (d = 7) : ()
    d = d
    i.portrait = case i.equipedlocation
      when :hand
        if i.material == :wood then ["wand", "handaxe"].sample + d.to_s
        else ["daggar","katara","sword","spear","lance"].sample + d.to_s
        end
      when :twohand
        if i.material == :wood then ["staff","bow","composite","spear","lance"].sample + d.to_s
        else ["greataxe", "bastard"].sample + d.to_s
        end
      when :handshield
        if i.material == :wood then "lightshield" + d.to_s
        else "heavyshield" + d.to_s
        end
      when :head 
        if i.material == :leather then "hat" + (d > 3 ? (3) : (d.to_s))
        else "helmet" + (d > 4 ? (4) : (d.to_s))
        end
      when :neck
        "neck" + d.to_s
      when :body
        if i.material == :leather then "robe" + d.to_s
        else "armor" + d.to_s
        end
      when :feet
        "feet" + d.to_s
      when :finger
        "ring" + d.to_s
      end
    if random(1, 100) <= 10 then i.effect = randomeffect() else nil end
    if i.equipedlocation == (:body||:legs||:handshield)
      i.effect={}
      i.effect[:armor] = {power: random(20, 35)}
    elsif i.equipedlocation == (:feet||:arms||:head)
      i.effect={}
      i.effect[:armor] = {power: random(5, 20)}
    end
    i.charge = self.chargemax unless i.effect.nil?
    i.name = itemname(material, equipedlocation, effect)
    i.save
    p i
  end
  
  def itemname(m, l, e=nil)
    name = ""
    if !e.nil? then e = "of " + e.keys.to_s end
    name = m.to_s + " " + l.to_s
    name += (" " + e) unless e.nil?
    name
  end
  
  def randomeffect()
    effect = Hash.new
    key = [:fire,:cold,:shock,:status,:preventstatus,:statup,:defense,:evasion,].sample
    if key == (:status or :preventstatus)
      effect[key] = {type: [:blind,:deaf,:mute,:burnt,:frozen,:stunned].sample, power: random(2, 6), cost: random(1, 3)}
    elsif key == :statup
      effect[key] = {type: [:strength,:stamina,:deterity,:intellegence,:intuition,:resolve,:persuasion].sample, power: random(3, 10)}
    else
      effect[key] = {power: random(1, 5), cost: random(1, 2)}
    end
    effect
  end
  
  def price
    p = self.quality * 2 + self.durability * 3 + self.chargemax * 5
    p += self.effect.length * 100 unless self.effect.nil?
    if self.material==:gold then p *= 7 elsif self.material==:silver then p *= 3 elsif self.material==:steel then p *= 1.2 end
    p
  end
  
  def durabilitymax
    l = self.quality / 1.618 
    if self.effect
      l -= self.effect.length * 0.7
    end
    if self.material == :iron
      l *= 2
    elsif self.material == :steel
      l *= 3.14
    else
      l *= 0.7
    end
    if self.equipedlocation == (:hand||:twohand||:handsheild)
      l *= 1.618
    else
      l *= 0.7
    end
    l.round
  end
  
  def chargemax
    l = self.durability
    if self.material == (:wood || :leather)
      l *= 2
    else
      l *= 0.7
    end
    if self.equipedlocation == (:finger || :neck || :head)
      l *= 1.5
    else
      l *= 0.7
    end
    l.round
  end
  def use(effect, target, cost)
    target.effect
    self.charge -= cost
    if self.charge <= 0
      self.destroy
    end
  end
  def package
    i = self.as_json
    ["_id", "character_id", "place_id", "created_at", "updated_at"].each do |k|
      i.delete(k)
    end
    i["durabilitymax"] = self.durabilitymax
    i["chargemax"] = self.chargemax
    i
  end
end
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
class Location
  include Mongoid::Document  
  field :terrain, type: Symbol 
  field :resource, type: Integer, :default => lambda { 8000 + (rand 14000-8000)}
  field :coordinates, type: Array, default: []
  validates_uniqueness_of :coordinates
  index({coordinates: "2d"}, {min: -180, max: 180, unique: true, background: true})
  field :portrait, type: String
  
  has_many :users
  has_many :characters
  has_many :places

  def Location.generate(coordinates)
    (coordinates[0] - 0.009..coordinates[0]).step(0.001) do |i|
      (coordinates[1] - 0.009..coordinates[1]).step(0.001) do |j| 
        c = [i,j].map{|k|k.round(3)}
        Location.create(coordinates: c) unless Location.where(coordinates: c).exists?
      end
    end
    #   r = (r * 1000).to_i
    #   (r*-1..r).each do |y|
    #     half_row_width = Math.sqrt(r*r - y*y).to_i
    #     (half_row_width*-1..half_row_width).each do |x|
    #       c = [(long + x).to_f / 1000, (lat + y).to_f / 1000]
    #       Location.create(coordinates: c) unless Location.where(coordinates: c).exists?
    #     end
    #   end
    # end
    
  end
  
  after_create do |t|
    if t.terrain.nil?
      tile = [:bingo, :grass1, :grass1, :grass1, :grass1, :grass1, :grass2, :grass3, :grass4, :bingo, :grass1].sample 
      if tile == :bingo 
        tile = [:forest1, :waterfish, :forest2, :forest3, :forest4, :forest5, :forest4, :forest5, :forestdeep, :forestfruit, :forestmushroom, :water].sample
      end
      t.terrain = tile
    else
      tile = t.terrain
    end
    t.portrait = ["./images/portrait.jpg", "./images/portrait2.jpg", "./images/portrait3.jpg"][rand(3)]
    if [:water, :waterfish].include? tile
      rand(0..3).times do
        tile = [:water, :waterfish, :water].sample
        delta = [t.coordinates, [(rand(-1..1).to_f/1000),(rand(-1..1).to_f/1000)]].transpose.map(&:sum).map{|i| i.round(3)}
        if Location.where(coordinates: delta).exists?
          Location.find_by(coordinates: delta).update_attributes(terrain: tile) 
        else
          Location.create(coordinates: delta, terrain: tile)
        end
      puts "splitting "+tile.to_s+" @ "+delta.to_s
      end
    elsif [:forestdeep, :forestfruit, :forestmushroom].include? tile
      (-1..1).each do |i|
        (-1..1).each do |j|
          c = [t.coordinates, [i.to_f/1000, j.to_f/1000]].transpose.map(&:sum).map{|k| k.round(3)}
          l = Location.where(coordinates: c)
          if (c != t.coordinates and !(rand(1..3)==3))
            if !l[0].nil?
              l=l[0]
              k= case l.terrain
                when (:water || :waterfish)
                  l.terrain
                when (:forest2 || :forest3 || :forest4)
                  [:forestdeep, :forestfruit, :forestmushroom].sample
                else [:forest2, :forest3, :forest4].sample
              end
              l.update_attributes(terrain: k) unless k == l.terrain
              puts l.terrain.to_s+" spread over "+l.coordinates.to_s unless t == l.terrain
            else
              m = [:forest1, :forest2, :forest3, :forest4, :forest5].sample
              Location.create(coordinates: c, terrain: m)
              puts m.to_s+" grew @ "+c.to_s
            end
          end
        end
      end
    end
    t.save
    puts "just created "+t.terrain.to_s+" @ "+t.coordinates.to_s
  end
  
  def package
    l = self.as_json
    ["_id", "users_id", "characters_id", "places_id", "created_at", "updated_at"].each do |k|
      l.delete(k)
    end
    l
  end
end
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
class Place
  include Mongoid::Document
  field :name, type: Symbol
  field :kind, type: Symbol
  field :chiral, type: Symbol
  field :chiralname, type: Symbol
  belongs_to :location
  
  field :occupants, type: Array
  
  field :gold, type: Integer
  has_many :items
  
  before_create do |p|
    while p.location.places.length >= 3
      newcoordinates = [p.location.coordinates, [(rand(-1..1).to_f/1000),(rand(-1..1).to_f/1000)]].transpose.map(&:sum).map{|i| i.round(3)}
      puts "uh oh, this tile is full, trying #{newcoordinates}"
      newlocation = Location.find_by(coordinates: newcoordinates)
      newlocation = Location.create(coordinates: newcoordinates) if newlocation.nil?
      p.location = newlocation
    end
    if [:forest1, :forest2, :forest3, :forest4, :forest5, :forestdeep, :forestfruit, :forestmushroom].include? self.location.terrain
      break if p.location.places.length <2
      self.location.terrain = [:grass1, :grass2, :grass3, :grass4].sample
    elsif [:water, :waterfish].include? self.location.terrain
      self.location.terrain = [:grass1, :grass2, :grass3, :grass4].sample
    end
  end
  
  after_create do |p|
    p.kind = Place.whatkind(p.location)
    p.name = Place.randomname
    rand(3..17).times{p.items.create}
    #p.character.generate 1
    p.gold = rand(50...300)
    p.location.update_attributes(terrain: :grass1)
    p.save
    puts p.name.to_s+" @ "+p.location.coordinates.to_s
  end
  
  def package
    p = self.as_json
    p["coordinates"] = self.location.coordinates
    p["items"] = []
    self.items.each{|i| p["items"].push i.package}
    ["_id", "location_id", "created_at", "updated_at", "chiral"].each do |k|
      p.delete(k)
    end
    p
  end
  
  def sell(item, character)
    # check to see if character has the money
    if character.gold > item.gold
      # take money
      character.gold -= item.price
      self.gold += item.price
      # give item, remove item from self
      self.items.pop(item)
      character.items.push item
    end
  end
  
  def buy(item, character)
    #check see if the vendor wants to buy the item
    # if yes  
    if self.gold > item.gold
      # take money
      self.gold -= item.price
      character.gold += item.price
      # give item, remove item from self
      self.items.push item
      character.items.pop item
    end
    # if no
      # reply why you don't want it    
  end
  
  def self.rumor
    self.occupants.sample
  end
  
  def Place.generate(coordinates)
    box = ""
    box += (coordinates[0] - 0.009).to_s # longitude west 
    box += ","
    box += (coordinates[1] - 0.009).to_s # latitude south
    box += ","
    box += (coordinates[0]).to_s # longitude east
    box += ","
    box += (coordinates[1]).to_s # latitude north
    places = {}
    ["amenity", "shop"].each do |i| # 
      uri = URI.parse(URI.encode("http://www.overpass-api.de/api/xapi?node[#{i}=*][bbox=#{box}]"))
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.request(Net::HTTP::Get.new(uri.request_uri))
      h = Hash.from_xml(response.body)
      places[i] = h["osm"]["node"]
    end
    places.each do |key, value|
      if value.nil?
        puts "couldn't find any geolocations in sector, randomizing..."
        coordinates2 = [coordinates[0], coordinates[1]].each{|i|(i+0.001*rand(-10..0)).round(3)}
        puts "placing a random structure at #{coordinates2}"
        rand(0..3).times do
          l = Location.find_by(coordinates: coordinates2)
          l.places.create # (chiral: c)
        end
      else
        puts "found geo locations in sector..."
        value.each do |v|
          v = Place.transform(key, v)
          unless v.nil?
            l = Location.find_by(coordinates: [v["lon"], v["lat"]])
            c = (v["id"] or ((v["name"]or"")+v["lon"].to_s+","+v["lat"].to_s))
            unless l.nil? or Place.where(chiral: c).exists?
              cn = v["name"]
              l.places.create(chiral: c, chiralname: cn)
            end
          end
        end
      end
    end
  end
  def Place.transform(k, v)
    p v
    if v.kind_of? Hash
      puts "transforming geolocation into place @ #{v["lon"]}, #{v["lat"]}"
      v["lat"] = v["lat"].to_f.round 3
      v["lon"] = v["lon"].to_f.round 3
      if v["tag"].class == Array
        v["tag"].each do |t|
          if t["k"] != ("source"||"created_by")
            v[t["k"]] = t["v"]
          end
        end
      elsif v["tag"].class == Hash
        if v["tag"]["k"] != ("source"||"created_by")
          v[v["tag"]["k"]] = v["tag"]["v"]
        end
      end
      v.delete("tag")
      v
    else
      nil
    end
  end
  def self.randomname()
    prefix = ["Aber","Ast","Auch","Ach","Bal","Brad","Car","Caer","Din","Dinas","Gill","Kin","King","Kirk","Lan","Lhan","Llan","Lang","Lin","Pit","Pol","Pont","Stan","Tre","Win","Whel"].sample
    suffix = ["shire","mire","more","wick","dale","ay","ey","y","bourne","burn","brough","burgh","bury","by","carden","cardine","don","den","field","forth","ghyll","ham","holme","kirk","mere","port","stead","wick"].sample
    name = prefix + suffix
  end
  def Place.whatkind(l)
    if (l.places.length == 1)
      p=[:shack, :shack, :inn, :house, :shack, :shack, :house].sample
    else
      p=[:field, :farm, :field, :smith, :field2, :farm, :field2, :townhall, :farm, :smith].sample
    end
    p
  end
end


#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
                                    # ROUTES #
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#


  # USER #

before do
  if session[:user] then @user = session[:user] end
end
  
get '/user' do
  # creates or logs in with new user.
  if request.xhr?
    # are we logging in?
    if params[:'user.email'] == nil
      l = Location.find_by(coordinates: JSON.parse(params[:coordinates]))
      @user = l.users.create()
    elsif !User.authenticate(params[:email], params[:password]).nil?
      @user = User.find_by(email: params[:email])
    else
      status 401
    end
    session[:user] = @user.id
    resp = Hash.new
    uc = []
    @user.characters.each{|c|uc << c.package}
    resp["user"] = @user.package
    resp["char"] = uc
    content_type :json
    resp.to_json
  else
    status 404
  end
end

# post '/user/update' do
#   if request.xhr?
#    #check if logged in, if so, upsert included information.
#    #if new user, store email and password, send a confirmation email.
#   end  
# end

get '/user/logout' do
  logout!
  @user = nil
  redirect '/'
end

  # LOCATION #

get '/location/' do
  coordinates = params[:coordinates].map{|i|(i.to_f*100).ceil/100.0}
  puts "request recieved to selecting tiles around sector #{coordinates}"
  resp = {}
  locations = []
  places = []
  #   total = (Math::PI * (params[:r].to_i ** 2)).round
  #   params[:r] = (params[:r].to_f)/1000
  #   current = Location.where(:coordinates.within_circle => [params[:coordinates], params[:r]]).count
  # check if there is a tile at the keystone location.
  selected = selectsector(coordinates)
  if params[:negativecoordinates]
    puts "negative coordinates present, selecting out #{params[:negativecoordinates]}"
    negative = params[:negativecoordinates].map{|i|i.split(",").map{|j|(j.to_f).round(2)}}
    knockout = negative.map{|i|selectsector(i)}.flatten(1).uniq
    selected = selected - knockout
  end
  puts "selected area #{selected}"
  selected.each do |c|
    puts "dealing with area #{c}"
    l = Location.where(coordinates: c)
    unless l.exists?
      puts "could not find keystone tiles, generating sectors..."
      puts "generating terrain around #{c}..."
      Location.generate(c)
      puts "generating places around #{c}..."
      Place.generate(c)
    end
    limits = [c, c.map{|i|(i - 0.009).round(2)}]
    puts "Found! preparing response within box - #{limits}"
    l = Location.where(:coordinates.within_box => limits).only(:coordinates, :resource, :terrain)
    l.each do |i| 
      if i.places?
        i.places.each do |p|
          p = p.package
          places << p
        end
      end
      i = i.package
      locations << i
    end
  end
  content_type :json
  resp["locations"] = locations
  resp["places"] = places
  puts "...Response Prepared... Sending..."
  resp.to_json
end
# 
# get '/location/:id' do
#   location = Location.find_by(url: params[:coordinate])
#   if location nil?
#     Location.generate(params[:coordinate], params[:r])
#     location = Location.find_by(url: params[:coordinate])
#   else
#     status 200
#     body(location.to_json)
#   end
# end

# post '/location/' do
#   if request.xhr?
#     params.each do |i|
#       l = Location.new(coordinates: i[1][:coordinates].split(",").map{|j|j.to_f}, terrain: i[1][:terrain].to_sym) 
#       l.upsert
#     end
#     status 200
#   else
#     status 404
#   end
# end

# put '/location/:geo' do
#   data = JSON.parse(request.body.string)
#   if data.nil? or !data.has_key? 'content' then
#     status 404
#   else
#     location = Location.new( #~#~#~ add stuff here! remember the comma
#       content: data[:terrain],
#       created: data[:character],
#       updated: data[:places]
#     ) 
#     location.save
#     status 200
#   end
# end

# post '/location/:id' do
#   data = JSON.parse(request.body.string)
#   if data.nil? then
#     status 404
#   else
#     location = Location.get(params[:id])
#     if location.nil? then
#       status 404
#     else
#       updated = false
#       %w().each do |k| #~#~#~ You need to put what fields to update
#         if data.has_key? k
#           location[k] = data[k]
#           updated = true
#         end
#       end
#       if updated then
#         location[:modified] = Time.now
#         !location.save ? (status 500) : (status 200)
#       end
#     end
#   end
# end
# 
# delete '/location/' do
#   #delete all
#   status 200 unless admin?
# end
# 
# delete '/location/:id' do
#   location = Location.get(params[:id])
#   if location nil? then
#     status 404
#   else
#     location.destroy ? (status 200) : (status 500)
#   end
# end

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

get "/js/script.js" do
  content_type "text/javascript", :charset => 'utf-8'
  coffee :script
end
get "/js/isometric2.js" do
  content_type "text/javascript", :charset => 'utf-8'
  coffee :isometric2
end
get "/js/components.js" do
  content_type "text/javascript", :charset => 'utf-8'
  coffee :components
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
    %meta{name: "keywords", content: @keywords}
    %meta{name: "viewport", content: "width=device-width,user-scalable=0,initial-scale=1.0,minimum-scale=1.0,maximum-scale=1.0"}
    %link{href: "/css/normalize.css", rel: "stylesheet"}
    %link{href: "/css/popup.css", rel: "stylesheet"}
    %link{href: "/style.css", rel: "stylesheet"}
    %script{src: "/js/modernizr.js"}
  %body
    %menu
    %div#container
      = yield
  %footer
  %script{src: "/js/lovely/core-1.1.0.js", type: "text/javascript"}
  %script{src: "/js/crafty-min.js", type: "text/javascript"}
  %script{src: "/js/underscore-min.js", type: "text/javascript"}  
  %script{src: "/js/isometric2.js", type: "text/javascript"}
  %script{src: "/js/components.js", type: "text/javascript"}
  %script{src: "/js/script.js", type: "text/javascript"}
  
@@index

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
