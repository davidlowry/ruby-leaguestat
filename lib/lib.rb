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

  def self.fetch(settings)
    client, league, dd = settings[:client], settings[:league], settings[:startOfWeek]
    feedDataURL = "http://cluster.leaguestat.com/lsconsole/json-week.php?client_code="+client+"&league_code="+league+"&type=gamelist&forcedate=" + dd 
    # puts feedDataURL
    resp = Net::HTTP.get_response(URI.parse(feedDataURL))
    return resp.body
  end
end

# class LeagueStatSettings
#   # Loads settings
#   def self.get
#     read_config
#   end
# end

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