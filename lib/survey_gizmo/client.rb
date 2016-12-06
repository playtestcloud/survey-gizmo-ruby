require 'active_support/core_ext/module/delegation'

module SurveyGizmo
  class Client
    def get(route)
      Retriable.retriable(retriable_args) { connection.get(route) }
    end

    def post(route, params)
      Retriable.retriable(retriable_args) { connection.post(route, params) }
    end

    def put(route, params)
      Retriable.retriable(retriable_args) { connection.put(route, params) }
    end

    def delete(route)
      Retriable.retriable(retriable_args) { connection.delete(route) }
    end

    def configuration
      raise 'Not configured!' unless @configuration
      @configuration
    end

    def warn(*args)
      logger.warn(*args) if configuration.api_debug
    end

    def debug(*args)
      logger.debug(*args) if configuration.api_debug
    end

    def configure
      reset!
      yield(@configuration) if block_given?
    end

    def logger
      SurveyGizmo::Logger.new(
        configuration.api_token,
        configuration.api_token_secret,
        STDOUT
      )
    end

    def reset!
      @configuration = Configuration.new
    end

    def connection
      faraday_options = {
        url: configuration.api_url,
        params: {
          api_token: configuration.api_token,
          api_token_secret: configuration.api_token_secret
        },
        request: {
          timeout: configuration.timeout_seconds,
          open_timeout: configuration.timeout_seconds
        }
      }

      Faraday.new(faraday_options) do |connection|
        connection.request :url_encoded

        connection.response(:parse_survey_gizmo_data)
        connection.response(:json, content_type: /\bjson$/)

        if configuration.api_debug
          connection.response(
            :logger,
            logger,
            bodies: true
          )
        else
          connection.response(:logger, logger)
        end

        connection.adapter Faraday.default_adapter
      end
    end

    def retriable_args
      self.class.retriable_args(configuration)
    end

    def self.retriable_args(configuration)
      {
        base_interval: configuration.retry_interval,
        tries: configuration.retry_attempts + 1,
        on: [
          Errno::ETIMEDOUT,
          Faraday::Error::ClientError,
          Net::ReadTimeout,
          SurveyGizmo::BadResponseError,
          SurveyGizmo::RateLimitExceededError
        ],
        on_retry: Proc.new do |exception, tries|
          warn(
            "Retrying after #{exception.class}: #{tries} attempts."
          )
        end
      }
    end

    def account_teams
      ResourceClient.new(self, SurveyGizmo::API::AccountTeam)
    end

    def campaigns
      ResourceClient.new(self, SurveyGizmo::API::Campaign)
    end

    def contacts
      ResourceClient.new(self, SurveyGizmo::API::Contact)
    end

    def email_messages
      ResourceClient.new(self, SurveyGizmo::API::EmailMessage)
    end

    def options
      ResourceClient.new(self, SurveyGizmo::API::Option)
    end

    def pages
      ResourceClient.new(self, SurveyGizmo::API::Page)
    end

    def questions
      ResourceClient.new(self, SurveyGizmo::API::Question)
    end

    def responses
      ResourceClient.new(self, SurveyGizmo::API::Response)
    end

    def surveys
      ResourceClient.new(self, SurveyGizmo::API::Survey)
    end
  end
end
