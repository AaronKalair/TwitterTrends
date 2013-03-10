require 'sinatra'
require 'haml'
require './jacob/lib/jacob.rb'


# Homepage
get '/' do
  haml :index
end

# Trend getting initalisation
get '/start' do
     puts params[:lat].to_f
     puts params[:lng].to_f
     puts params[:radius].to_f
    @@trends = TwitterConnector.new params[:lat].to_f, params[:lng].to_f, params[:radius].to_f
    @@trends.getTrends
    @@trends.extractor.keywordsToJSON
end

# Get the latest list of trends
get '/gettrends' do
  @@trends.extractor.keywordsToJSON
end

# Get the two next images
get '/getimages' do
  @@trends.extractor.imagesToJSON
end
