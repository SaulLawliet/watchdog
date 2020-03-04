require 'open-uri'

RSpec.describe Watchdog do
  it "has a version number" do
    expect(Watchdog::VERSION).not_to be nil
  end

  # 发件者配置是否正确
  it "sender success" do
    # 只有打开的测试开关, 才测试邮件发送
    if Watchdog::Config.get["test_sender"]
      sender = Watchdog::Sender.get_sender
      if sender.is_a?(Watchdog::MailSender)
        via = sender.get_via
        if via != :TODO
          expect(File.executable?("/usr/sbin/sendmail")).to eq(true) if via == :sendmail

          Watchdog::Sender.send("noreply@example.com", "Hello", "<html><h1>Hello world.</h1></html>")
        end
      end
    end
  end

  # 代理设置是否正确
  it "proxy success" do
    proxy = Watchdog::Config.get["proxy"]
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
  it "all user is right" do
    Watchdog::User.get_users.each do |name, address|
      expect(name).not_to be nil
      expect(address).not_to be nil
    end
  end

  # 检查 rule 配置是否正确
  it "all rule is right" do
    Watchdog::Rule.get_rules.each_value do |rule|
      expect(rule.name).not_to be nil
      expect(rule.url).not_to be nil
      expect(rule.css_selectors).not_to be nil
    end
  end

  # 检查 following 配置手否正确
  it "all following is right" do
    Watchdog::Following.get_followings.each_value do |following|
      expect(following.rule).not_to be nil
      expect(following.cron).not_to be nil
      expect(following.followers).not_to be nil

      # 检查 rule
      expect(Watchdog::Rule.get_rule(following.rule)).not_to be nil

      # 检查 followers
      following.followers.each do |name|
        expect(Watchdog::User.get_user(name)).not_to be nil
      end
    end
  end

end
