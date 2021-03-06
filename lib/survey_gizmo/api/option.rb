module SurveyGizmo
  module API
    class Option
      include SurveyGizmo::Resource
      include SurveyGizmo::MultilingualTitle

      attribute :id,            Integer
      attribute :survey_id,     Integer
      attribute :page_id,       Integer
      attribute :question_id,   Integer
      attribute :value,         String
      attribute :title,         String
      attribute :properties,    Hash

      @route = '/survey/:survey_id/surveypage/:page_id/surveyquestion/:question_id/surveyoption'
    end
  end
end
