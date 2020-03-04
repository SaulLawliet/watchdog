module Watchdog
  class Following
    class << self
      @@followings = {}

      def initialize
        followings = Config.get["followings"]
        unless followings.nil?
          followings.each do |following|
            struct = OpenStruct.new(following)

            if struct.param_name.nil?
              id = struct.rule
            else
              id = "#{struct.rule}(#{struct.param_name})"
            end

            @@followings[id] = struct
          end
        end
        show
      end

      def show
        puts "Follow List:"
        @@followings.each { |k, v| puts "%-25s %s" % [k, v] }
        puts
      end

      def get_followings
        @@followings
      end

      def get_following(id)
        @@followings[id]
      end

      def start_scheduler
        scheduler = Rufus::Scheduler.new

        @@followings.each do |id, following|
          if following.followers.length > 0
            scheduler.cron following.cron do
              check(id)
            end
          end
        end

        scheduler.join
      end

      def check_update(id)
        body = Fetch.fetch(id).to_s

        file_name = File.join(DIR_DATA, id)
        old = File.read(file_name) if File.exist?(file_name)
        if body == old
          # @@logger.info "[#{id}] No updates."
          return
        end
        # @@logger.info "[#{id}] Found new."
        # save to tmp file
        File.open(file_name, "w") { |f| f << body}

        following = Following.get_following(id)
        rule = Rule.get_rule(following.rule)

        subject = rule.name % following.param_name
        html_body = "<html>#{body}</html>"
        following.followers.each do |name|
          user = User.get_user(name)
          Sender.send(user.address, subject, html_body)
        end
      end

    end
  end
end
