# Watchdog
IF (网页某区域有变化) THEN (邮件提醒你)

# 如何配置
1. 规则: 放在`rules`目录下, 文件名要以`.yaml`结尾, 格式如下
  ```
  # file: rules/ituring.yaml
  name: "图灵电子书每周半价"                      # 邮件标题
  url: "http://www.ituring.com.cn/"               # 抓取的页面
  css_selectors: ".eve-list dl:nth-child(1) dd"   # 抓取的节点
  ```
  对于 `css_selectors` 如何食用, 请搭配
  [SelectorGadget](https://chrome.google.com/webstore/detail/selectorgadget/mhjhnkcfbdhnjickkkdbjoemdmbfginb).

1. 用户: 文件为 `user.yaml`, 格式如下
  ```
  # user@example.com 接收 ituring.yaml 和 ikea.yaml 这两个规则的变更提醒
  # user2@example.com 接收 ituring.yaml 规则的变更提醒

  - email: "user@example.com"
    following: ["ituring", "ikea"]
  - email: "user2@example.com"
    following: ["ituring"]
  ```

# 获取并执行
```
git clone https://github.com/SaulLawliet/watchdog.git
cd watchdog
ruby watchdog.rb
```
推荐加入到定时任务里
```
# 每天10点执行
0 10 * * * cd /path/to/watchdog && /path/to/ruby-x.x.x/wrappers/ruby watchdog.rb
```
