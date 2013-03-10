require 'alchemy_api'
require_relative('../../MyConfig')
require 'url_expander'
require 'twitter-text'
require 'instagram'

# Add OEmbed Support to the Instagram class by holoiii on github
module Instagram
  class Client
    def oembed(*args)
      url = args.first
      return nil unless url
      get("oembed?url=#{url}", {}, false, true)
    end
  end
end

class DataAnalytics

  attr_accessor :keywords_count, :images
  # How long a keyword should remain in the hash
  VALID_MINUITES = 5

  def initialize
    #A new hash to store the keywords in
    @keywords_count = Hash.new(0)
    # An array to store the URL of any images
    @images = Array.new
    # Struct to store the time that a keyword was added to the hash
    @word_time = Struct.new(:word, :time)
    # Queue for storing word times on
    @queue = []

    # Set up the Alchemy API
    AlchemyAPI.configure do |config|
      config.apikey = MyConfig::ALCHEMY_KEY
    end

    # Set up the Instagram API
    Instagram.configure do |config|
      config.client_id = MyConfig::INSTAGRAM_CLIENT_ID
      config.client_secret = MyConfig::INSTAGRAM_CLIENT_SECRET
    end
  end

  # Removes any @ mentions from the tweets and returns the modified tweet e.g. @bob what you doing today would return "what you doing today"
  def stripAtMentions tweet
    remove = tweet.gsub!(/@\w+/, "")
    # Remove returns nil if it removed nothing and we need the tweet to pass to another method so return the tweet if nothing changed
    if remove.nil?
      return tweet
    # If we did remove some @ mentions return the modified tweet
    else
      return remove
    end
  end

  # Expands the given url or returns the URL if it was not in shortned form
  def expandURL url
    begin
      UrlExpander::Client.expand(url, :config_file => File.expand_path( File.dirname(__FILE__) + "/../../url_expander_credentials.yml" ))
    # The method throws an error if the given URL was not a shortened URL so if we get this error return the original URL
    rescue
      return url
    end
  end

  # Remove words that I've found to be inappropriate as keywords
  def removeBlackListedWords tweet
    tweet.gsub!(/\brt\b|\blol\b/i, "")
  end

  # Extract all of the desired information from a tweet
  def processTweet tweet
    tweet = extractHashTags tweet
    tweet = stripAtMentions tweet
    tweet = extractImages tweet
    tweet = removeBlackListedWords tweet
    extractKeywords tweet
    removeExpiredKeywords VALID_MINUITES
  end

  # Extracts the keywords from a given tweet and adds them to the hash
  def extractKeywords tweet
  semaphore = Mutex.new
    begin
      results = AlchemyAPI::search(:keyword_extraction, :text => tweet)
      unless results.nil?
        results.each do |keyword|
          semaphore.synchronize do
            # Increment the count for this keyword
            @keywords_count[keyword['text'].downcase] = @keywords_count[keyword['text'].downcase] + 1
            # Add it to the keyword queue
            @queue << @word_time.new( keyword['text'].downcase, Time.now)
          end
        end
      end
    rescue
      # If something went wrong with this API call then just give up on it and move on
    end

  end

  #Extracts any hashtags from tweets adds them to the keywords hash and returns the tweet without the hashtags in it
  def extractHashTags tweet
    semaphore = Mutex.new
    tweet.scan(/#\w+/).each do |hashtag|
      semaphore.synchronize do
        @keywords_count[hashtag.downcase] = @keywords_count[hashtag.downcase] + 1
        # Add it to the keyword queue
        @queue << @word_time.new( hashtag.downcase, Time.now)
      end
      tweet.gsub!(hashtag, "")
    end
    tweet
  end

  #Extracts any image urls from tweets, currently we get twitter images from the tweet meta data so this extracts instagram photos
  def  extractImages tweet
    semaphore = Mutex.new
    # Extract the urls
    urls = Twitter::Extractor.extract_urls tweet
    urls.each do |url|
      semaphore.synchronize do
        checkInstagram ( expandURL (url) )
        tweet.gsub!(url, "")
      end
    end
    tweet
  end

  # Determines if the given URL is to an image on Instagram and if so extracts the image URL and adds it to the list of images
  def checkInstagram url
    # Check if this url is a link to an instagram picture, checks for with and without www. and for the shortened and non shortened instagram URL
    if(  (/http:\/\/www\.instagr\.am\/p\// =~ url) == 0 || (/http:\/\/www\.instagram\.com\/p\// =~ url) == 0 || (/http:\/\/instagram\.com\/p\// =~ url) == 0 || (/http:\/\/instagr\.am\/p\// =~ url) == 0 )
      # This part could throw an exception if the image is private
      begin
        semaphore = Mutex.new
        # Get the media ID
        data = Instagram::oembed url
        # Get the image url
        image = Instagram::media_item data.media_id
        # And add it to the list of images
        semaphore.synchronize do
          @images << image.images.standard_resolution.url
        end
      rescue
        # We dont have to do anything if the exception is thrown it just means we cant use the image
      end
    end
  end

  # Prints the top 5 keywords in the keywords hash
  def printKeywords
    keywords_count.sort_by { |keyword, frequency| -frequency }[0..5].each do |keyword, value|
      puts keyword + " - " + value.to_s
    end
  end

  # Prints all the images in the images array
  def printImages
    images.each do |image|
      puts image
    end
  end

  # Converts the top 5 keywords into a JSON string
  def keywordsToJSON
    str = "{ "
    keywords_count.sort_by { |keyword, frequency| -frequency }[0..5].each_with_index do |keyword, index|
      str += "\"" + index.to_s + "\" : \"" + keyword[0] + "\", "
    end
    # Remove the final ","  and white space then insert the final }
    str[0 .. -3] += "}"
  end

  # Remove all keywords from the hash that have been there for longer than max mins
  def removeExpiredKeywords max_mins
    unless @queue.first.nil?
      # While the keyword at the head of the queue was added more than max_mins ago
      while @queue.first.time  + max_mins * 60 < Time.now or @queue.first.nil?
        # If this is the last instance of this keyword then delete it from the hash
        if @keywords_count[@queue.first.word]  == 1
          @keywords_count.delete(@queue.first.word)
          # Remove it from the queue
          @queue.shift
        else
          # Deduct it from the keyword count
          @keywords_count[@queue.first.word] = @keywords_count[@queue.first.word] - 1
          # Remove it from the queue
          @queue.shift
        end
      end
    end
  end

  # Converts the next two images in the array into a JSON string
  def imagesToJSON
    str = "{"
    2.times do |index|
      unless images.empty?
        current = images.shift
        str += "\"" + index.to_s + "\" : \"" + current + "\", "
      end
    end
    # Remove the final ","  and white space then insert the final }
    str[0 .. -3] += "}"
  end

end
