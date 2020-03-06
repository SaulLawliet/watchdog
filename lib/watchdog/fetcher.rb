module Watchdog
  class Fetcher
    attr_accessor :id

    class << self
      @@fetchers = {}

      def initialize
        Dir.glob("#{DIR_FETCHERS}/*") do |filename|
          # foo/bar.ooo => [foo, bar, ooo]
          split = filename.split(/\/|\./)

          case split[2] # filename_extension
          when "yaml", "yml"
            fetcher = CssSelectorsFetcher.new(filename)
          when "rb"
            fetcher = RunScriptFetcher.new(filename)
          end

          fetcher.id = split[1]
          @@fetchers[fetcher.id] = fetcher
        end

        show
      end

      def show
        puts "Fetcher List:"
        @@fetchers.each { |k, v| puts "%-25s %s" % [k, v.to_s] }
        puts
      end

      def get_fetchers
        @@fetchers
      end

      def get_fetcher(fetcher)
        @@fetchers[fetcher]
      end

    end

    # 获得ID
    def get_id(options)
      raise "子类需要实现该方法"
    end

    # 获得名字
    def get_name(options)
      raise "子类需要实现该方法"
    end

    # 抓取内容
    def fetch(options)
      raise "子类需要实现该方法"
    end


  end

  class RunScriptFetcher < Fetcher

    def initialize(filename)
      instance_eval("def fetch(options); #{File.read(filename)}; end")
    end

    def get_name(options)
      if options.nil?
        nil
      else
        options.name
      end
    end

  end

  class CssSelectorsFetcher < Fetcher
    attr_accessor :data

    def initialize(filename)
      @data = OpenStruct.new(YAML.load_file(filename))
    end

    def get_name(options)
      options.nil? ?  data.name : data.name % options.param_name
    end

    def get_id(options)
      options.nil? ?  @id : "#{@id}(#{options.param_name})"
    end

    def fetch(options)
      CssSelectorsFetcher.fetch(@data, options)
    end

    def to_s
      "CssSelectorsFetcher(#{@data})"
    end

    class << self
      @@UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36"

      def fetch(data, options)
        headers = {"User-Agent" => @@UA}
        headers[:proxy] = CONFIG["proxy"] if data.proxy

        if options.nil?
          url = data.url
        else
          url = data.url % options.param_url
        end

        url = URI::encode(url)
        body = Nokogiri::HTML(open(url, headers).read).css(data["css_selectors"])

        uri = URI(url)
        body.each {|element| loop_element(uri.scheme, uri.host, element)}

        "<html>#{body}</html>"
      end

      private
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

      def modify_relative_link(scheme, host, attr)
        if attr.value[0] == '/'
          if attr.value[1] == '/'
            attr.value = "#{scheme}:#{attr.value}"
          else
            attr.value = "#{scheme}://#{host}#{attr.value}"
          end
        end
      end
    end

  end
end
