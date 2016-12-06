require 'logger'

module SurveyGizmo
  class Logger < ::Logger
    def initialize(api_token, api_token_secret, *args)
      super(*args)
      @api_token = api_token
      @api_token_secret = api_token_secret
    end

    def format_message(severity, timestamp, progname, msg)
      msg.gsub!(/#{Regexp.quote(@api_token)}/, '<SG_API_KEY>') if @api_token
      msg.gsub!(
        /#{Regexp.quote(@api_token_secret)}/, '<SG_API_SECRET>'
      ) if @api_token_secret

      "#{timestamp.strftime('%Y-%m-%d %H:%M:%S')} #{severity} #{msg}\n"
    end
  end
end
