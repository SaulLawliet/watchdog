module Watchdog
  class User
    class << self

      @@users = {}

      def initialize
        users = CONFIG["users"]
        unless users.nil?
          users.each do |user|
            struct = OpenStruct.new(user)
            @@users[struct.name] = struct
          end
        end
        show
      end

      def show
        puts "User List:"
        @@users.each { |k, v| puts "%-25s %s" % [k, v] }
        puts
      end

      def get_users
        @@users
      end

      def get_user(name)
        @@users[name]
      end

    end
  end
end
