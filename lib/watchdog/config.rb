module Watchdog
  class Config
    class << self
      @@config = {}

      def initialize
        @@config = YAML.load_file('config.yaml')
      end

      def get
        @@config
      end
    end
  end
end
