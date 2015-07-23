require 'pp'

Dir.glob(File.expand_path("../whatnot/*", __FILE__)).each { |f| require f }
