require 'survey_gizmo/api/question'

module SurveyGizmo
  module API
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
        return @questions if @questions.all? { |q| q.sub_question_skus.all? { |sku| @questions.find { |q| q.id == sku } } }

        # See note on broken subquestions in resource.rb.
        with_subquestions = @questions
        @questions.each do |q|
          with_subquestions.reject! { |q| q.sub_question_skus.include?(q.id) }
          with_subquestions += q.sub_questions
        end

        @questions = with_subquestions.each { |q| q.attributes = children_params }
      end
    end
  end
end
