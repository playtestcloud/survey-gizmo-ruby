require 'survey_gizmo/api/option'

module SurveyGizmo::API
  class Question
    include SurveyGizmo::Resource
    include SurveyGizmo::MultilingualTitle

    attribute :id, Integer
    attribute :base_type, String
    attribute :type, String
    attribute :description, String
    attribute :shortname, String
    attribute :comment, Boolean
    attribute :properties, Hash
    attribute :after, Integer
    attribute :options, Array[Option]
    attribute :survey_id, Integer
    attribute :page_id, Integer, default: 1
    attribute :sub_questions, Array[Question]
    attribute :parent_question_id, Integer

    alias_attribute :subtype, :type

    @route = {
      get:    '/survey/:survey_id/surveyquestion/:id',
      create: '/survey/:survey_id/surveypage/:page_id/surveyquestion',
      update: '/survey/:survey_id/surveypage/:page_id/surveyquestion/:id'
    }
    @route[:delete] = @route[:update]

    def survey
      @survey ||= @client.surveys.first(id: survey_id)
    end

    def options
      return parent_question.options.dup.each { |o| o.question_id = id } if parent_question

      @options ||= @client.options.all(children_params.merge(all_pages: true)).to_a
      @options.each { |o| o.attributes = children_params }
    end

    def parent_question
      return nil unless parent_question_id
      @parent_question ||= @client.questions.first(survey_id: survey_id, id: parent_question_id)
    end
  end
end
