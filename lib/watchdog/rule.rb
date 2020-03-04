module Watchdog
  class Rule
    class << self
      @@rules = {}

      def initialize
        Dir.glob("#{DIR_RULES}/*.yaml") do |rule|
          name = "#{rule}".split(/\/|\./)[1]
          @@rules[name] = OpenStruct.new(YAML.load_file(rule))
        end

        show
      end

      def show
        puts "Rule List:"
        @@rules.each { |k, v| puts "%-25s %s" % [k, v] }
        puts
      end

      def get_rules
        @@rules
      end

      def get_rule(rule)
        @@rules[rule]
      end

    end

  end
end
