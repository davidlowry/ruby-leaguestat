require 'lib/leaguestat.rb'

# gamestats from http://cluster.leaguestat.com/lsconsole/json-week.php?client_code=X&league_code=X

# Provides access to fixtureList, made up of fixtues, which expose date, home team, away team, score [+more if ya want]
# this is basic, and early days.

# Purpose
# - to scrape accurate future fixture info + scrape accurate scoring data from an authoritive source 

#instantiate and get scores for this week
ls = LeagueStat.init('2013-4-5')
puts ls.fixtureList.inspect
# Get scores for a particular week
# ls.getScoresFor('2012-11-1')
