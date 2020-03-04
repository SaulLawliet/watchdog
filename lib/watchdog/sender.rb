module Watchdog
  class Sender

    class << self
      @@sender = nil

      def initialize
        config = Watchdog::Config.get

        via = config["sender"]
        case via
        when "mail"
          @@sender = MailSender.new
        else
          raise "不支持的发送者: " + via
        end

        @@sender.load_config(config[via])
      end

      def send(to, subject, body)
        @@sender.send(to, subject, body)
      end

      def get_sender
        @@sender
      end

    end

    def load_config(config)
      raise "子类需要实现该方法"
    end

    def send(to, subject, body)
      raise "子类需要实现该方法"
    end

  end

  class MailSender < Sender

    def load_config(config)
      @options = config.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      @options[:via] = @options[:via].to_sym
      smtp_options = @options.delete(:smtp_options)
      if @options[:via] == :smtp
       @options[:via_options] = smtp_options.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
       @options[:via_options][:authentication] = @options[:via_options][:authentication].to_sym
      end

      @subject_prefix = @options.delete(:subject_prefix)
    end

    def send(to, subject, html_body)
      Pony.mail(options = @options.merge({
        :to => to,
        :subject => "#{@subject_prefix}#{subject}",
        :html_body => html_body
      }))
    end

    def get_via
      @options[:via]
    end

  end
end
