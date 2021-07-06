class ApplicationController < ActionController::Base
    def hello
        render html: Rails.application.secrets[:telegram_key]
    end
end
