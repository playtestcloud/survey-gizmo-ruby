module SurveyGizmo
  module API
    class Response
      include SurveyGizmo::Resource

      # Filters
      NO_TEST_DATA =   { field: 'istestdata', operator: '<>', value: 1 }
      ONLY_COMPLETED = { field: 'status',     operator: '=',  value: 'Complete' }

      attribute :id, Integer
      attribute :survey_id, Integer
      attribute :contact_id, Integer
      attribute :data, String
      attribute :status, String
      attribute :is_test_data, Boolean
      attribute :sResponseComment, String
      attribute :variable, Hash
      attribute :meta, Hash
      attribute :shown, Hash
      attribute :url_variables, Hash
      attribute :survey_data, Hash
      attribute :date_submitted, DateTime
      attribute :date_started, DateTime
      attribute :language, String
      attribute :ip_address, String
      attribute :referer, String
      attribute :user_agent, String
      attribute :longitude, String
      attribute :latitude, String
      attribute :country, String
      attribute :city, String
      attribute :region, String
      attribute :postal, String
      alias_attribute :submitted_at, :date_submitted
      alias_attribute :answers, :survey_data

      @route = '/survey/:survey_id/surveyresponse'

      def survey
        @survey ||= @client.surveys.first(id: survey_id)
      end

      def parsed_answers
        answers.map do |k, v|
          Answer.new(
            children_params.merge(
              key: k,
              value: v,
              submitted_at: submitted_at
            )
          )
        end
      end
    end
  end
end
