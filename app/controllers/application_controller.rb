class ApplicationController < ActionController::Base
    def hello
        # render html: Rails.application.secrets[:telegram_key]
        render html: ENV['TELEGRAM_KEY']
    end
end
