require File.expand_path('../config/environment', __dir__)
require "dry/inflector"
require 'telegram/bot'

# token = Rails.application.secrets[:telegram_bot_token]
token = ENV['TELEGRAM_BOT_TOKEN']

Telegram::Bot::Client.run(token) do |bot|
    bot.listen do |message|
        #p message
        # p message.text
        # bot.api.send_message(chat_id: message.chat.id, text: "hi b")
        if !User.exists?(telegram_id: message.chat.id)
           user = User.create(telegram_id: message.from.id, name: message.from.first_name)
        else
          user = User.find_by(telegram_id: message.from.id)
        end

        case user.step
        when "add"
          user.bots.create(username: message.text)
          user.step = "description"
          user.save
          bot.api.send_message(chat_id: message.chat.id, text: "Ok, Please share description")
        when "description"
          new_bot = user.bots.last
          new_bot.description = message.text
          new_bot.save
          bot.api.send_message(chat_id: message.chat.id, text: "Thank you, I have saved your bot!")
          user.step = nil
          user.save
        when "delete"
          if user.bots.map{ |u_bot| u_bot.username }.include?(message.text)
            Bot.find_by(username: message.text).destroy
            bot.api.send_message(chat_id: message.chat.id, text: "Ok, I have deleted #{message.text}!")
          else
            bot.api.send_message(chat_id: message.chat.id, text: "Unable to find Bot #{message.text}")
          end
          user.step = nil
          user.save
        when "search"
          bots = Bot.where("description LIKE ?", "%#{message.text}%")
          bot.api.send_message(chat_id: message.chat.id, text: "Search Results:")
          if !bots.size.zero?
            bots.each do |s_bot|
              bot.api.send_message(chat_id: message.chat.id, text: "#{s_bot.username}:#{s_bot.description}")
            end
          else
            bot.api.send_message(chat_id: message.chat.id, text: "Sorry, we cannot find any results for #{message.text}.")
          end
          user.step = nil
          user.save
        end

        case message.text
        when '/start'
          bot.api.send_message(chat_id: message.chat.id, text: "Hi! Welcome to kc's first attempt at making a telegram bot, use /add, /search, /delete to navigate around! Have fun!")
        when '/add'
          user.step = "add"
          user.save
          bot.api.send_message(chat_id: message.chat.id, text: "Sure, what is the bot username?" )
        when '/delete'
          user.step = "delete"
          user.save
          arr = user.bots.map{ |u_bot| u_bot.username }
          markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: arr)
          bot.api.send_message(chat_id: message.chat.id, text: "ok, Which bot to delete?", reply_markup: markup )
        when '/search'
          user.step = "search"
          user.save            
          bot.api.send_message(chat_id: message.chat.id, text: "What to find?" )
        end
    end
end
