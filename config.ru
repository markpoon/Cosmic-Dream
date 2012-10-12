require './application'
URI::DEFAULT_PARSER = 
  URI::Parser.new(:UNRESERVED => URI::REGEXP::PATTERN::UNRESERVED + '|')
run Sinatra::Application