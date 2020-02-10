module SurveyGizmo::API
  class Campaign
    include SurveyGizmo::Resource

    attribute :id,               Integer
    attribute :name,             String
    attribute :type,             String
    attribute :subtype,          String
    attribute :status,           String
    attribute :uri,              String
    attribute :SSL,              Boolean
    attribute :slug,             String
    attribute :language,         String
    attribute :close_message,    String
    attribute :limit_responses,  String
    attribute :token_variables,  Array
    attribute :survey_id,        Integer
    attribute :date_created,     DateTime
    attribute :date_modified,    DateTime

    @route = '/survey/:survey_id/surveycampaign'

    def contacts(conditions = {})
      @client.contacts.all(conditions.merge(children_params).merge(all_pages: !conditions[:page]))
    end
  end
end
