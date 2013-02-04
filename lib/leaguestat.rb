require 'rubygems'
require 'json'
require 'net/http'
require 'yaml'

# Loads settings
SETTINGS = YAML::load('lib/config.yml')




@startOfWeek = Date.now.beginning_of_week #.advance(:days => -1)
@feedData = nil

def cleanLeagueStat(str)
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
  
  return clean
end

def getData(dd)
  
  feedDataURL = "http://cluster.leaguestat.com/lsconsole/json-week.php?client_code="+SETTINGS.client_code+"&league_code="+SETTINGS.league_code+"&type=gamelist&forcedate=" + dd
  
  return @feedData unless @feedData.nil?
  
  resp = Net::HTTP.get_response(URI.parse(feedDataURL))
  data = resp.body
  
  clean = cleanLeagueStat(data)
  #puts clean
  @feedData = JSON.parse(clean)
  
  if @feedData.has_key? 'Error'
    raise "web service error"
  end
  
  makeFixturesList()
  
  return @feedData
end

def makeFixturesList
  @feedData["fixtures"] = []
  
  (@feedData.keys - ['configStr', 'fixtures']).each do |k|
    v = @feedData[k]
    addFixtures(v) unless v.empty? || v["Num"].nil? || v["Num"]==0
  end
  puts @feedData["fixtures"].inspect
end

def addFixtures(data)
  quantity = data['Num'].to_i
  
  (1..quantity).each do |i|
    puts data["Game#{i}"].inspect
    game = data["Game#{i}"]
    @feedData["fixtures"] << {
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

def getScores(dd)
  data = getData(dd);
end
