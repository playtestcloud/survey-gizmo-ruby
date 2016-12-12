module SurveyGizmo
  class Configuration
    DEFAULT_API_VERSION = 'v5'.freeze
    DEFAULT_RESULTS_PER_PAGE = 50
    DEFAULT_TIMEOUT_SECONDS = 300
    DEFAULT_RETRIES = 3
    DEFAULT_RETRY_INTERVAL = 60
    DEFAULT_REGION = :us
    DEFAULT_LOG_LEVEL = Logger::FATAL

    REGION_INFO = {
      us: {
        url: 'https://restapi.surveygizmo.com',
        locale: 'Eastern Time (US & Canada)'
      },
      eu: {
        url: 'https://restapi.surveygizmo.eu',
        locale: 'Berlin'
      }
    }.freeze

    attr_accessor :api_token
    attr_accessor :api_token_secret

    attr_accessor :api_debug
    attr_accessor :api_url
    attr_accessor :api_time_zone
    attr_accessor :api_version
    attr_accessor :results_per_page

    attr_accessor :timeout_seconds
    attr_accessor :retry_attempts
    attr_accessor :retry_interval
    attr_accessor :log_level

    def initialize
      @api_token = ENV['SURVEYGIZMO_API_TOKEN'] || nil
      @api_token_secret = ENV['SURVEYGIZMO_API_TOKEN_SECRET'] || nil

      @api_version = DEFAULT_API_VERSION
      @results_per_page = DEFAULT_RESULTS_PER_PAGE

      @timeout_seconds = DEFAULT_TIMEOUT_SECONDS
      @retry_attempts = DEFAULT_RETRIES
      @retry_interval = DEFAULT_RETRY_INTERVAL
      self.region = DEFAULT_REGION

      @log_level = DEFAULT_LOG_LEVEL
      @api_debug = ENV['GIZMO_DEBUG'].to_s =~ /^(true|t|yes|y|1)$/i
    end

    def region=(region)
      region_infos = REGION_INFO[region]
      ArgumentError.new("Unknown region: #{region}") unless region_infos

      @api_url = region_infos[:url]
      @api_time_zone = region_infos[:locale]
    end
  end
end
