require 'yaml'

def read_config(file="config/config.yml")
	config = YAML.load_file(file)
	return config['settings']
end