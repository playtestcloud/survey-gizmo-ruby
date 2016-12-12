module SurveyGizmo
  module API
    class EmailMessage
      include SurveyGizmo::Resource

      attribute :id,                Integer
      attribute :survey_id,         Integer
      attribute :campaign_id,       Integer
      attribute :invite_identity,   Integer
      attribute :type,             String
      attribute :subtype,          String
      attribute :subject,           String
      attribute :replies,           String
      attribute :message_type,       String
      attribute :medium,            String
      attribute :status,            String
      attribute :from,              Hash
      attribute :body,              Hash
      attribute :send,              Boolean
      attribute :date_created,       DateTime
      attribute :date_modified,      DateTime

      @route = '/survey/:survey_id/surveycampaign/:campaign_id/emailmessage'
    end
  end
end
