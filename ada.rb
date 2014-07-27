require 'cinch'
require 'dotenv'
require 'redis'
require 'json'

Dotenv.load
Process.daemon(nochdir = true)
r = Redis.new(:host => ENV['REDISHOST'], :port => ENV['REDISPORT'])

class TimedPlugin
  include Cinch::Plugin

  timer 60, method: :timed
  def timed
    r = Redis.new(:host => ENV['REDISHOST'], :port => ENV['REDISPORT'])
    # 5分前
    date = (Time.now + 60*5)
    day = date.strftime("%m/%d")
    time = date.strftime("%H:%M")
    r.keys.each do |key|
      event_info = JSON.parse(r[key])
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

  helpers do
    def reboot m
      m.reply "ｻﾖｳﾅﾗ ..."
      m.reply "reboot #{Process.pid} #{$0}"
    end
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
      reboot m
    else
      m.reply "最新の code 取得に失敗しました."
    end
  end

  on :message, /^#{ENV['NICK']}(: | )reboot$/ do |m|
    reboot m
  end

  on :message, /^#{ENV['NICK']}(: | )down$/ do |m|
    Process.kill(:QUIT, $$)
  end

end

bot.start

