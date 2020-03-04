require "watchdog/version"
require "watchdog/config"
require "watchdog/fetch"
require "watchdog/following"
require "watchdog/rule"
require "watchdog/sender"
require "watchdog/user"

require 'find'
require 'logger'
require 'nokogiri'
require 'open-uri'
require 'ostruct'
require 'pony'
require 'rufus-scheduler'
require 'yaml'

module Watchdog
  class Error < StandardError; end

  # 配置目录
  DIR_DATA = "data"
  DIR_RULES = "rules"

  CHECK_LOGGER = Logger.new("check.log")
  CHECK_LOGGER.datetime_format = "%Y-%m-%d %H:%M:%S"

  Dir.mkdir(DIR_DATA) unless File::directory?(DIR_DATA)

  # 加载系统配置
  Config.initialize

  # 加载规则
  Rule.initialize

  # 加载发送方式
  Sender.initialize

  # 加载用户
  User.initialize

  # 加载订阅
  Following.initialize

end
