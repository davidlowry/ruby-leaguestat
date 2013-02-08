# require 'yaml'
# 
# puts "x #{File.join(File.dirname(__FILE__), '/../config/config.yml')}"
# 
# def read_config(file=File.expand_path(File.join(File.dirname(__FILE__), '../', '/config/config.yml')))
#   puts File.expand_path(File.join(File.dirname(__FILE__), '../', '/config/config.yml'))
#   config = YAML.load_file(file)
#   return config['settings']
# end