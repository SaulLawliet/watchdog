require "watchdog/version"
require "watchdog/fetcher"
require "watchdog/following"
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

  CONFIG = YAML.load_file('config.yaml')

  # 配置目录
  DIR_DATA = "data"
  DIR_FETCHERS = "fetchers"

  Dir.mkdir(DIR_DATA) unless File::directory?(DIR_DATA)

  # 监控日志
  CHECK_LOGGER = Logger.new("check.log")
  CHECK_LOGGER.datetime_format = "%Y-%m-%d %H:%M:%S"

  # 加载发送方式
  Sender.initialize

  # 加载用户
  User.initialize

  # 加载规则
  Fetcher.initialize

  # 加载订阅
  Following.initialize

end
