module Watchdog
  class Following
    class << self
      @@followings = {}

      def initialize
        followings = CONFIG["followings"]
        unless followings.nil?
          followings.each do |following|
            struct = OpenStruct.new(following)

            unless struct.options.nil?
              struct.options = OpenStruct.new(struct.options)
            end

            fetcher = Fetcher.get_fetcher(struct.fetcher)
            raise "不存在的 fetcher #{struct.fetcher}" if fetcher.nil?

            @@followings[fetcher.get_id(struct.options)] = struct
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

        @@followings.each do |following_id, following|
          if following.followers.length > 0
            scheduler.cron following.cron do
              check_update(following_id)
            end
          end
        end

        scheduler.join
      end

      def check_update(following_id)
        following = get_following(following_id)
        fetcher = Fetcher.get_fetcher(following.fetcher)

        status = true
        begin
          body = fetcher.fetch(following.options)
        rescue Exception => e
          status = false
          # body = e.full_message # from ruby 2.5
          body = e.message
        end

        if status
          file_name = File.join(DIR_DATA, following_id)
          old = File.read(file_name) if File.exist?(file_name)
          if body == old
            CHECK_LOGGER.info "[#{following_id}] No updates."
            return
          end
          CHECK_LOGGER.info "[#{following_id}] Found new."

          # save to tmp file
          File.open(file_name, "w") { |f| f << body}
        end

        subject = fetcher.get_name(following.options)

        following.followers.each do |name|
          user = User.get_user(name)
          Sender.send(user.address, subject, body)
        end
      end

    end
  end
end
