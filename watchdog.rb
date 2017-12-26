# coding: utf-8
require "open-uri"
require "yaml"
require "logger"

require "nokogiri"
require "pony"
require "colorize"
require "rufus-scheduler"

# add blank?
class NilClass
  def blank?
    true
  end
end

class String
  def blank?
    empty?
  end
end

class Watchdog
  class << self
    @@UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36"

    @@logger = Logger.new("check.log")
    @@logger.datetime_format = "%Y-%m-%d %H:%M:%S"

    @@DIR_DATA = "data"
    @@DIR_RULES = "rules"
    @@FILE_CONFIG = "config.yaml"

    @@SUCCESS = true
    @@PROXY = ""

    def run
      config = YAML.load_file(@@FILE_CONFIG)
      unless ARGV.select { |arg| arg == "-t"}.empty?
        load_mail(config["mail"])
        if @@SUCCESS
          send_mail({ :subject => "这是一个测试邮件" })
          succ "Test mail has been sent. Please check your mail."
        end
        return
      end
      Dir.mkdir(@@DIR_DATA) unless File::directory?(@@DIR_DATA)
      load_config?(config)
      if @@SUCCESS
        succ "System started."
        start_scheduler
      else
        error "System error. Abort."
      end
    end

    private

    def load_config?(config)
      @@PROXY = config["proxy"] unless config["proxy"].blank?

      load_mail(config["mail"])
      load_following?(config["following"])
    end

    def load_mail(mail)
      info("Load mail.")
      @@SUCCESS &= error("mail is null.") if mail.nil?
      @@SUCCESS &= error("mail['to'] is empty.") if mail["to"].blank?

      if mail["from"].blank?
        mail["from"] = "noreply@example.com"
        warn("mail['from'] is empty. So using '#{mail["from"]}'.")
      end

      case mail["via"]
      when "sendmail"
      when "smtp"
        @@SUCCESS &= error("mail['smtp-options'] is null.") if mail["smtp-options"].nil?
        mail["smtp-options"] = mail["smtp-options"].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      else
        @@SUCCESS &= error("mail['via'] is error.")
      end

      @@MAIL = mail if @@SUCCESS
    end

    def load_following?(following)
      info("Load following.")
      @@FOLLOWING = {}
      if following.class == Array
        following.each do |info|
          data = load_info(info)
          @@SUCCESS &= error("same key:#{data['id']}") if @@FOLLOWING.key?(data['id'])
          @@FOLLOWING[data['id']] = data
        end
      end
      @@SUCCESS &= error("no following.") if @@FOLLOWING.empty?
    end

    def load_info(info)
      id = info['rule']
      data = YAML.load_file("#{@@DIR_RULES}/#{info['rule']}.yaml")

      ["name", "url", "css_selectors"].each do |key|
          @@SUCCESS &= error("[#{id}] '#{key}' not config") if data[key].blank?
      end

      if data["name"].index("{0}")
        @@SUCCESS &= error("#{id} info['param-name'] is null.") if info["param-name"].blank?
        id += "(#{info["param-name"]})"
        data["name"] = data["name"].gsub("{0}", info["param-name"])
      end

      if data["url"].index("{0}")
        @@SUCCESS &= error("#{id} info['param-url'] is null.") if info["param-url"].blank?
        data["url"] = data["url"].gsub("{0}", info["param-url"])
      end
      data["url"] = URI::encode(data["url"])

      @@SUCCESS &= error("proxy is null") if (not info["proxy"].nil?) && info["proxy"] && @@PROXY.blank?

      info("  #{id}.")

      ["rule", "param-name", "param-url"].each {|x| info.delete(x)}

      { "id" => id }.merge(info).merge(data)
    end

    def start_scheduler
      scheduler = Rufus::Scheduler.new

      @@FOLLOWING.each do |k, v|
        scheduler.cron v["cron"] do
          check(k)
        end
      end

      scheduler.join
    end

    def check(k)
      v = @@FOLLOWING[k]

      headers = {"User-Agent" => @@UA}
      headers[:proxy] = @@PROXY if v["proxy"]
      new = Nokogiri::HTML(open(v["url"], headers).read).css(v["css_selectors"])

      file_name = File.join(@@DIR_DATA, k)
      old = File.read(file_name) if File.exist?(file_name)
      if new.to_s == old
        @@logger.info "[#{k}] No updates."
        return
      end
      @@logger.info "[#{k}] Found new."

      # save to tmp file
      File.open(file_name, "w") { |f| f << new}

      # handle relative path
      uri = URI(v["url"])
      new.each {|element| loop_element(uri.scheme, uri.host, element)}

      # notify
      send_mail({:subject => v["name"], :html_body => "<html>#{new}</html>"})
    end

    def send_mail(data)
      data = data.merge({
        :to => @@MAIL["to"],
        :from => @@MAIL["from"],
        :via => @@MAIL["via"].to_sym
      })
      data[:subject] = "#{@@MAIL["subject-prefix"]}#{data[:subject]}"
      data[:via_options] = @@MAIL["smtp-options"] if data[:via] == :smtp
      Pony.mail(data)
    end

    def modify_relative_link(scheme, host, attr)
      if attr.value[0] == '/'
        if attr.value[1] == '/'
          attr.value = "#{scheme}:#{attr.value}"
        else
          attr.value = "#{scheme}://#{host}#{attr.value}"
        end
      end
    end

    def loop_element(scheme, host, element)
      itself = element.itself
      case itself.name
      when "img"
        modify_relative_link(scheme, host, itself.attributes["src"])
      when "a"
        modify_relative_link(scheme, host, itself.attributes["href"])
      end

      element.children.each do |child|
        loop_element(scheme, host, child) if element.is_a?(Nokogiri::XML::Element)
      end
    end

    def info(str)
      puts "[INFO]  - #{str}"
      true
    end

    def succ(str)
      puts "[SUCC]  - #{str}".green
      true
    end

    def warn(str)
      puts "[WARN]  - #{str}".yellow
      true
    end

    def error(str)
      puts "[ERROR] - #{str}".red
      false
    end

  end
end

Watchdog.run
