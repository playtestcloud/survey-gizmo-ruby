module SurveyGizmo::API
  class Answer
    include Virtus.model

    attribute :key,           String
    attribute :value,         String
    attribute :survey_id,     Integer
    attribute :response_id,   Integer
    attribute :question_id,   Integer
    attribute :question_text, String
    attribute :question_type, String
    attribute :option_id,     Integer
    attribute :submitted_at,  DateTime
    attribute :answer_text,   String
    attribute :other_text,    String
    attribute :question_pipe, String

    def initialize(attrs = {})
      self.attributes = attrs
      self.question_id = value['id']
      self.question_text = value['question']
      self.question_type = value['type']

      if value['options']
        self.answer_text = selected_options_texts.join(', ')
      else
        self.answer_text = value['answer']
      end
    end

    def selected_options_texts
      selected_options.map do |opt|
        opt['answer']
      end
    end

    def selected_options
      value['options'].values.reject do |opt|
        opt['answer'].nil?
      end
    end

    # Strips out the answer_text when there is a valid option_id
    def to_hash
      {
        response_id: response_id,
        question_id: question_id,
        option_id: option_id,
        question_pipe: question_pipe,
        submitted_at: submitted_at,
        survey_id: survey_id,
        other_text: other_text,
        answer_text: option_id || other_text ? nil : answer_text
      }.reject { |k, v| v.nil? }
    end
  end
end
