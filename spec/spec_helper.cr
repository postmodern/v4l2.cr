require "../src/v4l2"
require "spectator"

Spectator.configure do |config|
  config.formatter = Spectator::Formatting::DocumentFormatter.new
end
