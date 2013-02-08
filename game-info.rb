require 'lib/leaguestat.rb'

# gamestats from http://cluster.leaguestat.com/lsconsole/json-week.php?client_code=X&league_code=X

#instantiate and get scores for this week
ls = LeagueStat.init('2013-4-5')
    puts ls.fixtureList.inspect
# Get scores for a particular week
# ls.getScoresFor('2012-11-1')
