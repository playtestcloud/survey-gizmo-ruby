require 'survey_gizmo/api/question'

module SurveyGizmo::API
  class Page
    include SurveyGizmo::Resource
    include SurveyGizmo::MultilingualTitle

    attribute :id,            Integer
    attribute :description,   String
    attribute :properties,    Hash
    attribute :after,         Integer
    attribute :survey_id,     Integer
    attribute :questions,     Array[Question]

    @route = '/survey/:survey_id/surveypage'

    def survey
      @survey ||= @client.surveys.first(id: survey_id)
    end

    def questions
      @questions.each { |q| q.attributes = children_params }
      @questions.each do |q|
        q.client = @client
      end
      @questions
    end
  end
end
