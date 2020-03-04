module Watchdog
  class Fetch
    class << self
      @@UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36"

      def fetch(following_id)
        following = Following.get_following(following_id)
        rule = Rule.get_rule(following.rule)

        headers = {"User-Agent" => @@UA}
        headers[:proxy] = Config.get["proxy"] if following.proxy

        url = rule.url % following.param_url
        url = URI::encode(url)
        html = Nokogiri::HTML(open(url, headers).read).css(rule["css_selectors"])

        uri = URI(url)
        html.each {|element| loop_element(uri.scheme, uri.host, element)}
        return html
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
