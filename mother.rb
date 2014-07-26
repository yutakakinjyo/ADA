require 'cinch'
require 'dotenv'

Dotenv.load
Process.daemon(nochdir = true)

bot = Cinch::Bot.new do
  configure do |c|
    c.server = ENV['SERVER']
    c.port = ENV['PORT']
    # dotenv で配列そのまま定義できないの
    c.channels = ENV['CHANNELS'].split(",")
    c.nick = ENV['MOTHER_NICK']
    c.realname = ENV['REALNAME']
    c.user = ENV['USERNAME']
    c.password = ENV['PASSWORD']
  end

  on :message, /^reboot ([0-9]+) (.+)/ do |m, pid, bot_file|
    m.reply "#{pid} を再起動"
    if Process.kill(:QUIT, pid.to_i) == 1
      m.reply "#{bot_file} 終了を確認. 起動をかけます"
      `ruby #{bot_file}`
    else
      m.reply "シャットダウンに失敗"
    end
  end

  on :message, /^#{ENV['MOTHER_NICK']}(: | )down$/ do |m|
    Process.kill(:QUIT, $$)
  end

end

bot.start

