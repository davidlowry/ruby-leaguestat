require 'rubygems'

class LeagueStatFixtureList
  attr_accessor :fixtures
  
  def generate(fd)
    self.fixtures = []
    (fd.keys - ['configStr', 'fixtures']).each do |k|
      dateData = fd[k]
      unless dateData.empty? || dateData["Num"].nil? || dateData["Num"]==0
        self.fixtures += addFixturesForDate(dateData)
      end
    end
    self.fixtures
  end
    
  def addFixturesForDate(dateData)
    quantity = dateData['Num'].to_i
    
    (1..quantity).map do |fixture_id|
      
      identifier = "Game#{fixture_id}"
      game = dateData[identifier]
      LeagueStatFixture.generate(
        :date => game["Date"],
        :home => game["HomeTeam"]["Name"],
        :away => game["VisitingTeam"]["Name"],
      :status => game["SmallStatus"],
       :score => parseScoreInformation(game)
      )
    end

  end

  def parseScoreInformation(game)
    # ?? return "-" if game["Pre-Game"] == "Pre-Game"
    game["HomeTeam"]["Score"] + ":" + game["VisitingTeam"]["Score"]
  end

end

class LeagueStatFixture
  attr_accessor :date, :home, :away, :status, :score
  def self.generate(gameData)
    ls = LeagueStatFixture.new
    gameData.each {|k,v| ls.send("#{k}=".to_sym,v)}
    return ls
  end
end


class LeagueStatFetchData
  require 'net/http'

  def self.fetch(client, league, dd)
    feedDataURL = "http://cluster.leaguestat.com/lsconsole/json-week.php?client_code="+client+"&league_code="+league+"&type=gamelist&forcedate=" + dd 
    # puts feedDataURL
    resp = Net::HTTP.get_response(URI.parse(feedDataURL))
    return resp.body
  end
end

class LeagueStatSettings
  # Loads settings
  require 'lib/config.rb'

  def self.get
    read_config
  end
end

class LeagueStatFeedCleanToJSON
  require 'json'
  def self.clean(str)
    fnr = [
      ['}\';', '},'],
      ['var configStr = \'', '"configStr":'],
      ['Starts at:', 'Starts at'],
      ["var todayData = '", '"todayData":'],
  
      ["var monData   = '", '"monData":'],
      ["var tueData   = '", '"tueData":'],
      ["var wedData   = '", '"wedData":'],
      ["var thuData   = '", '"thuData":'],
      ["var friData   = '", '"friData":'],
      ["var satData   = '", '"satData":'],
      ["var sunData   = '", '"sunData":'],
      ["load(configStr,todayData,tueData,wedData,thuData,friData,satData,sunData);", '']
    ]
    cleaning = str
    fnr.each do |find, replace|
      cleaning = cleaning.gsub(find, replace)
    end
    cleaning = cleaning.gsub(/http:/, 'REINSERTHTTPN')
    cleaning = cleaning.gsub(/https:/, 'REINSERTHTTPS')
    cleaning = cleaning.gsub(/::/, 'REINSERTWScontent')
    #switch the keys from : to ""=
    cleaning.gsub!(/([a-zA-Z]+):/, '"\1"=')
    cleaning = cleaning.gsub(/REINSERTWScontent/, '::')
    cleaning = cleaning.gsub(/REINSERTHTTPN/, 'http:')
    cleaning = cleaning.gsub(/REINSERTHTTPS/, 'https:')
    #make it more like json
    cleaning = "{#{cleaning}}"
    #remove last comma, as it will be isolated (from before the load(..) string)
    cleaning[cleaning.rindex(/,/)] = " "
    clean = cleaning
  
    return JSON.parse(clean)
  end
end

class LeagueStat
  
  attr_accessor :settings, :feedData, :fixtureList
  
  #
  # init
  #
  
  def self.init(startOfWeek = nil, settings = LeagueStatSettings.get)
    
    leaguestat = LeagueStat.new
    
    leaguestat.settings = settings
    
    leaguestat.settings['startOfWeek'] = leaguestat.parseTime(startOfWeek) if !startOfWeek.nil?
    #puts leaguestat.settings.inspect
    leaguestat.feedData = leaguestat.getData
    leaguestat.fixtureList = leaguestat.makeFixturesList
    
    return leaguestat
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
    
    settings['startOfWeek'] = parseTime(overrideDate)
    
    data = LeagueStatFetchData.fetch(settings['client_code'], settings['league_code'], settings['startOfWeek'])
  
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