require 'rubygems'

class LeagueStatFetchData
  require 'net/http'

  def self.fetch(client, league, dd)
    feedDataURL = "http://cluster.leaguestat.com/lsconsole/json-week.php?client_code="+client+"&league_code="+league+"&type=gamelist&forcedate=" + dd 
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
  
    cleaning.gsub!(/([a-zA-Z]+):/, '"\1"=')
    cleaning = cleaning.gsub(/REINSERTWScontent/, '::')
    cleaning = cleaning.gsub(/REINSERTHTTPN/, 'http:')
    cleaning = cleaning.gsub(/REINSERTHTTPS/, 'https:')
    cleaning = "{#{cleaning}}"
    cleaning[cleaning.rindex(/,/)] = " "
    clean = cleaning
  
    return JSON.parse(clean)
  end
end

class LeagueStat
  
  attr_accessor :settings, :feedData
  
  #
  # init
  #
  
  def self.init(startOfWeek = nil, settings = LeagueStatSettings.get)
    
    leaguestat = LeagueStat.new
    
    if startOfWeek.nil?
      t_now = Time.now
      startOfWeek = t_now - (t_now.wday-1)*24*60*60 - t_now.hour*60*60 - t_now.min*60 - t_now.sec
    end
    
    leaguestat.settings = settings
    leaguestat.settings['startOfWeek'] = "#{startOfWeek.year}-#{startOfWeek.month}-#{startOfWeek.day-2}" #'2013-2-2'
    leaguestat.feedData = nil
    
    return leaguestat
  end
  
  #
  # functions 
  #
  
  def getData(dd)
    
    return feedData unless feedData.nil?
  
    data = LeagueStatFetchData.fetch(settings['client_code'], settings['league_code'], dd)
  
    #puts clean
    feedData = LeagueStatFeedCleanToJSON.clean(data)
  
    if feedData.has_key? 'Error'
      raise "web service error"
    end
  
    makeFixturesList
  
    return feedData
  end

  def makeFixturesList
    puts feedData.inspect
    feedData['fixtures'] = Array.new
  
    (feedData.keys - ['configStr', 'fixtures']).each do |k|
      v = feedData[k]
      addFixtures(v) unless v.empty? || v["Num"].nil? || v["Num"]==0
    end
    puts "<h2>Fixtures</h2>"
    feedData["fixtures"].each do |f|
      puts "<p>"
      f.each do |k,v|
        puts "<strong>#{k}</strong> #{v}"
      end
      puts "</p>"
    end

  end

  def addFixtures(data)
    quantity = data['Num'].to_i
  
    (1..quantity).each do |i|
      game = data["Game#{i}"]
      feedData["fixtures"] << {
        "Date" => game["Date"],
        "Home" => game["HomeTeam"]["Name"],
        "Away" => game["VisitingTeam"]["Name"],
        "Status" => game["SmallStatus"],
        "Score" => parseScoreInformation(game)
      }
    end
  end

  def parseScoreInformation(game)
    # return "-" if game["Pre-Game"] == "Pre-Game"
    game["HomeTeam"]["Score"] + ":" + game["VisitingTeam"]["Score"]
  end

  def getScores(dd=settings['startOfWeek'])
    data = getData(dd)
  end
end