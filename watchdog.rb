# coding: utf-8
require "open-uri"
require "nokogiri"
require "pony"
require "yaml"
require "colorize"
require "rufus-scheduler"


class Watchdog
  class << self
    @@DIR_DATA = "data"
    @@DIR_RULES = "rules"
    @@FILE_USERS = "users.yaml"

    @@UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36"

    @@logger = Logger.new("check.log")
    @@logger.datetime_format = "%Y-%m-%d %H:%M:%S"

    @@RULES = {}

    def run
      Dir.mkdir(@@DIR_DATA) unless File::directory?(@@DIR_DATA)

      if load_rules? && load_users?
        puts "RUNNING...".green
        start_scheduler
      else
        puts "FOUND ERROR. Abort.".red
      end
    end

    private
    def load_rules?
      rt = true
      puts "Load rules...".yellow
      Dir.glob("#{@@DIR_RULES}/*.yaml").each do |file|
        flag = true
        id = file[@@DIR_RULES.size+1 ... file.size-5].to_sym # 5 means ".yaml".size
        data = YAML.load_file(file)
        ["name", "url", "css_selectors", "cron"].each do |key|
          if data[key].nil? || data[key].empty?
            puts "  FAILURE: [#{id}] '#{key}' not config".red
            flag = false
          end
        end
        if flag
          puts "  SUCCESS: [#{id}]".green
          @@RULES[id] = data.inject({}){|memo, (k,v)| memo[k.to_sym] = v; memo}.merge({:observers => []})
        else
          rt = false
        end
      end
      puts "DONE.\n".yellow
      rt
    end

    def load_users?
      rt = true
      puts "Load users...".yellow
      data = YAML.load_file(@@FILE_USERS)
      if data.is_a?(Array)
        data.each do |user|
          email = user["email"]
          puts "  for #{email}:"
          user["following"].each do |rule_id|
            if @@RULES.key?(rule_id.to_sym)
              @@RULES[rule_id.to_sym][:observers] << email
              puts "    SUCCESS: [#{rule_id}]".green
            else
              rt = false
              puts "    FAILURE: [#{rule_id}] (Legal rules: #{@@RULES.keys})".red
            end
          end
        end
      else
        rt = false
        puts "  FAILURE: no users".red
      end
      puts "DONE.\n".yellow
      rt
    end

    def start_scheduler
      scheduler = Rufus::Scheduler.new

      @@RULES.each do |k, v|
        next if v[:observers].empty?
        scheduler.cron v[:cron] do
          check(k)
        end
      end

      scheduler.join
    end

    def check(k)
      v = @@RULES[k]

      file_name = File.join(@@DIR_DATA, k.to_s)

      old = File.read(file_name) if File.exist?(file_name)
      new = Nokogiri::HTML(open(v[:url], {"User-Agent" => @@UA}).read).css(v[:css_selectors])

      if new.to_s == old
        @@logger.info "[#{k}] No updates."
        return
      end

      @@logger.info "[#{k}] Found new."
      # save to tmp file
      File.open(file_name, "w") do |file|
        file.print new.to_s
      end

      # handle relative path
      uri = URI(v[:url])
      new.each {|element| loop_element(uri.scheme, uri.host, element)}

      # notify
      v[:observers].each do |to|
        Pony.mail(:to => to,
                  :subject => "[订阅]#{v[:name]}",
                  :html_body => "<html>#{new}</html>",
                  :from => 'noreply@example.com', # you might change
                  :via => :sendmail               # you might change
                 )
      end
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

  end
end

Watchdog.run
