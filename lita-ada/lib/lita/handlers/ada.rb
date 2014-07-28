module Lita
  module Handlers
    class Ada < Handler
      route /^echo\s+(.+)/, :echo, help: {  "echo TEXT" => "Echoes back TEXT." }

      def echo(response)
        response.reply(response.matches)
      end

      route /^event list/, :event_list
      def event_list m
        $redis = Redis.new(:host => '127.0.0.1', :port => '6379')
        m.reply "hoge"
        m.reply "#{$redis.keys}"
        names = ""
        $redis.keys.each do |key|
          event_info = JSON.parse($redis[key])
          if event_info['channel'] == m.channel
            names += "\"#{event_info['name']}\", "
          end
        end
        m.reply names
      end
    end
    Lita.register_handler(Ada)
  end
end
