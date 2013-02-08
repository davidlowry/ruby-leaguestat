require "#{File.dirname(__FILE__)}/lib.rb"

class LeagueStat
  
  attr_accessor :settings, :feedData, :fixtureList
  
  def initialize(client, league, startOfWeek=nil)
    
    self.settings = Hash.new
    self.settings[:client] = client
    self.settings[:league] = league
    self.settings[:startOfWeek] = parseTime(startOfWeek.nil? ? nil : startOfWeek)
    
    #puts leaguestat.settings.inspect
    self.feedData = getData
    self.fixtureList = makeFixturesList
  end
  
  def parseTime(sow=nil)
    t_now = sow.nil? ? Time.now : Time.parse(Date.parse(sow).to_s)
    sow = t_now - (t_now.wday-1)*24*60*60 - t_now.hour*60*60 - t_now.min*60 - t_now.sec
    "#{sow.year}-#{sow.month}-#{(sow.day)}" #'2013-2-2'
  end
  
  
  #
  # functions 
  #
  
  def getData(overrideDate=nil)
    
    return feedData unless feedData.nil?
    
    self.settings[:startOfWeek] = parseTime(overrideDate)
    
    data = LeagueStatFetchData.fetch(settings)
  
    #puts clean
    feedData = LeagueStatFeedCleanToJSON.clean(data)
    
    # if feedData.has_key? 'Error'
    #   raise "web service error"
    # end

    return feedData
  end

  def makeFixturesList(fd=self.feedData)
    
    fl = LeagueStatFixtureList.new
    fl.generate(fd)

  end

  def getScoresFor(dd)
    #reset the feed
    self.feedData = nil
    #reload the feed
    self.feedData = getData(dd)
    #parse
    self.fixtureList = makeFixturesList
  end
end