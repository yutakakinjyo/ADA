require 'cinch'
require 'dotenv'
require 'redis'
require 'json'

Dotenv.load
r = Redis.new(:host => ENV['REDISHOST'], :port => ENV['REDISPORT'])

class TimedPlugin
  include Cinch::Plugin

  timer 60, method: :timed
  def timed
    r = Redis.new(:host => ENV['REDISHOST'], :port => ENV['REDISPORT'])
    # 5分前
    time = (Time.now + 60*5).strftime("%H:%M")
    r.keys.each do |key|
      event_info = JSON.parse(r[key])
      if /#{time}/ =~ event_info['name']
        Channel(event_info['channel']).send "#{event_info['name']} 5分前です"
      end
    end
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
    c.plugins.plugins = [TimedPlugin]
  end

  on :message, /^event add (.+)/ do |m, event_name|
    key = "#{event_name}#{m.channel}"
    if r.exists(key)
      m.reply "#{event_name} はすでに追加されています"
    else
      r[key] = {:name => event_name, :channel => m.channel}.to_json
      m.reply "#{event_name} をイベント一覧に追加しました"
    end
  end

  on :message, /^event list/ do |m|
    names = ""
    r.keys.each do |key|
      event_info = JSON.parse(r[key])
      if event_info['channel'] == m.channel
        names += "\"#{event_info['name']}\", "
      end
    end
    m.reply names
  end

  on :message, /^event delete (.+)/ do |m, event_name|
    key = "#{event_name}#{m.channel}"
    if r.exists(key)
      r.del(key)
      m.reply "#{event_name} を削除しました"
    else
      m.reply "#{event_name} は追加されていません"
    end
  end

  on :message, /^#{ENV['NICK']}(: | )強くなれ$/ do |m|
    m.reply "最新の code を git pull します ..."
    if system("git pull")
      m.reply "最新の code 取得に成功しました. これより再起動します"
      
    else
      m.reply "最新の code 取得に失敗しました."
    end
  end
end



bot.start

