# Watchdog
IF (网页某区域有变化) THEN (邮件提醒你)

# 邮件截图
<img src="screenshots/ituring.png" width="400px" /> <img src="screenshots/ikea.png" width="400px" />

# 如何配置
1. 规则: 放在`rules`目录下, 文件名要以`.yaml`结尾, 格式如下
  ```
  # file: rules/ituring.yaml
  name: "图灵电子书每周半价"                         # 邮件标题
  url: "http://www.ituring.com.cn/"               # 抓取的页面
  css_selectors: ".eve-list dl:nth-child(1) dd"   # 抓取的节点
  cron: "0 10 * * * "                             # 抓取的时间, 规则跟 crontab 一样
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
# 添加规则, 修改用户信息, 更改发送邮件方式
ruby watchdog.rb &
```

