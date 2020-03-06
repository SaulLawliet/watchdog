RSpec.describe Watchdog do
  it "has a version number" do
    expect(Watchdog::VERSION).not_to be nil
  end

  # 发件者配置是否正确
  it "sender success" do
    # 只有打开的测试开关, 才测试邮件发送
    if Watchdog::CONFIG["test_sender"]
      sender = Watchdog::Sender.get_sender
      if sender.is_a?(Watchdog::MailSender)
        via = sender.get_via
        if via != :TODO
          expect(File.executable?("/usr/sbin/sendmail")).to eq(true) if via == :sendmail

          address = "noreply@example.com"
          data = Watchdog::User.get_users.first
          unless data.nil?
            address = data[1].address
          end

          Watchdog::Sender.send(address, "Hello", "<html><h1>Hello world.</h1></html>")
        end
      end
    end
  end

  # 代理设置是否正确
  it "proxy success" do
    proxy = Watchdog::CONFIG["proxy"]
    unless proxy.empty?
      headers = {:proxy => proxy}
      open("https://example.com", headers)
    end
  end

  # 至少需要配置了一个用户
  it "at least one user" do
    expect(Watchdog::User.get_users.length).to be > 0
  end

  # 检查 user 配置是否正确
  it "all users are right" do
    Watchdog::User.get_users.each do |name, address|
      expect(name).not_to be nil
      expect(address).not_to be nil
    end
  end

  # 检查 fetcher 配置是否正确
  it "all fetchers are right" do
    Watchdog::Fetcher.get_fetchers.each_value do |fetcher|
      if fetcher.is_a?(Watchdog::CssSelectorsFetcher)
        expect(fetcher.data.name).not_to be nil
        expect(fetcher.data.url).not_to be nil
        expect(fetcher.data.css_selectors).not_to be nil
      end
    end
  end

  # 检查 following 配置手否正确
  it "all followings are right" do
    Watchdog::Following.get_followings.each_value do |following|
      expect(following.fetcher).not_to be nil
      expect(following.cron).not_to be nil
      expect(following.followers).not_to be nil

      # 检查 rule
      expect(Watchdog::Fetcher.get_fetcher(following.fetcher)).not_to be nil

      # 检查 followers
      following.followers.each do |name|
        expect(Watchdog::User.get_user(name)).not_to be nil
      end
    end
  end

  it "fetch example.com success" do
    fetcher = Watchdog::Fetcher.get_fetcher("example")
    expect(fetcher.fetch(nil)).to eq(fetcher.get_name(nil))
  end

end
