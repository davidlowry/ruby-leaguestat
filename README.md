ruby-leaguestat
===============

To parse and make data available in ruby from a leaguestat.com data source

Gamestats scrapable from http://cluster.leaguestat.com/lsconsole/json-week.php?client_code=X&league_code=X

Provides access to fixtureList, made up of fixtures, which expose date, home team, away team, score [+more available if ya want]

## Purpose

* to scrape accurate future fixture info + scrape accurate scoring data from an authoritive source
* leaguestat provide a visible API which is not locked to a referral URL or with a complex api key
* you'll need a valid client code + league code; which can be gleaned from implementations, but its not documented so don't abuse it

## Sample

Instantiate and get scores for this week
	
	require('lib/leaguestat.rb')
	ls = LeagueStat.init(client_code, league_code)
	puts ls.fixtureList.inspect

Get scores for a particular week

	ls = LeagueStat.init(client_code, league_code, '2012-11-1')
	# or
	ls.getScoresFor('2012-11-1')

## Status

* base class in lib/leaguestat.rb
* supporting classes in lib/lib.rb
* instantiation and public fixture list 
* readme.md created
* removed 

## TODO

* Catch errors especially with http calls
* Find a better way to parse JS to extract the JSON
* or make cleaning function more sane
* more access functions