# -*- coding: utf-8 -*-
require 'cinch'
require 'dotenv'
require 'redis'
require 'json'

Dotenv.load
Process.daemon(nochdir = true)

class TimedPlugin
  include Cinch::Plugin

  $redis = Redis.new(:host => ENV['REDISHOST'], :port => ENV['REDISPORT'])

  timer 60, method: :timed
  def timed
    # 5分前
    date = (Time.now + 60*5)
    day = date.strftime("%m/%d")
    time = date.strftime("%H:%M")
    $redis.keys.each do |key|
      event_info = JSON.parse($redis[key])
      if existDate event_info['name']
        if (isThatTime time, event_info['name']) && (isThatDay day, event_info['name'])
          Channel(event_info['channel']).send "#{event_info['name']} 5分前です"
        end
      else
        if isThatTime time, event_info['name']
          Channel(event_info['channel']).send "#{event_info['name']} 5分前です"
        end
      end
    end
  end

  def existDate str
    return /(\d\d)\/(\d\d)/ =~ str
  end

  def isThatDay day, str
    return /#{day}/ =~ str
  end

  def isThatTime time, str
    /#{time}/ =~ str
  end
end

class ADAPlugin
  include Cinch::Plugin

  $redis = Redis.new(:host => ENV['REDISHOST'], :port => ENV['REDISPORT'])

  def reboot m
      m.reply "ｻﾖｳﾅﾗ ..."
      m.reply "reboot #{Process.pid} #{$0}"
  end

  match /^event add (.+)/, :method => :event_add
  def event_add m, event_name
    key = "#{event_name}#{m.channel}"
    if $redis.exists(key)
      m.reply "#{event_name} はすでに追加されています"
    else
      $redis[key] = {:name => event_name, :channel => m.channel}.to_json
      m.reply "#{event_name} をイベント一覧に追加しました"
    end
  end

  match /^event list/, :method => :event_list
  def event_list m
    names = ""
    $redis.keys.each do |key|
      event_info = JSON.parse($redis[key])
      if event_info['channel'] == m.channel
        names += "\"#{event_info['name']}\", "
      end
    end
    m.reply names
  end

  match /^event delete (.+)/, :method => :event_delete
  def event_delete m, event_name
    key = "#{event_name}#{m.channel}"
    if $redis.exists(key)
      $redis.del(key)
      m.reply "#{event_name} を削除しました"
    else
      m.reply "#{event_name} は追加されていません"
    end
  end

  match /^#{ENV['NICK']}(: | )強くなれ$/, :method => :upgrade
  def upgrade m
    m.reply "最新の code を git pull します ..."
    if system("git pull")
      m.reply "最新の code 取得に成功しました. これより再起動します"
      reboot m
    else
      m.reply "最新の code 取得に失敗しました."
    end
  end

  match /^#{ENV['NICK']}(: | )reboot$/, :method => :call_reboot
  def call_reboot m
    reboot m
  end

  match /^#{ENV['NICK']}(: | )down$/, :method => :down
  def down m
    Process.kill(:QUIT, $$)
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = ENV['SERVER']
    c.port = ENV['PORT']
    # dotenv で配列そのまま定義できないの
    c.channels = ENV['CHANNELS'].split(",")
    c.nick = ENV['NICK']
    c.realname = ENV['REALNAME']
    c.user = ENV['USERNAME']
    c.password = ENV['PASSWORD']
    c.plugins.plugins = [TimedPlugin,ADAPlugin]
    c.plugins.prefix = nil
  end
end

bot.start

