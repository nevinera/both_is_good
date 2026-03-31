module BothIsGood
  def self.configuration = Configuration.global

  def self.configure = yield(configuration)
end

require_relative "both_is_good/version"
require_relative "both_is_good/configuration"
