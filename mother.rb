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

  on :message, /^reboot (.+)/ do |m, bot_file|
    m.reply "#{m.user.nick} を再起動します"
    m.reply "#{m.user.nick}: down"
    m.reply "#{bot_file} 終了命令を発行. 起動命令を発行"
    `ruby #{bot_file}`
  end

  on :message, /^#{ENV['MOTHER_NICK']}(: | )down$/ do |m|
    Process.kill(:QUIT, $$)
  end

end

bot.start

