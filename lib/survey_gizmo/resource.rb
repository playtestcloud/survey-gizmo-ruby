require 'set'
require 'addressable/uri'

module SurveyGizmo
  class URLError < RuntimeError; end

  module Resource
    extend ActiveSupport::Concern

    included do
      include Virtus.model
      instance_variable_set('@route', nil)
      SurveyGizmo::Resource.descendants << self
    end

    def self.descendants
      @descendants ||= Set.new
    end

    # These are methods that every API resource can use to access resources in SurveyGizmo
    module ClassMethods
      attr_accessor :route

      # Get an enumerator of resources.
      # @param [Hash] conditions - URL and pagination params with SurveyGizmo "filters" at the :filters key
      #
      # Set all_pages: true if you want the gem to page through all the available responses
      #
      # example: { page: 2, filters: { field: "istestdata", operator: "<>", value: 1 } }
      #
      # The top level keys (e.g. :page, :resultsperpage) get encoded in the url, while the
      # contents of the array of hashes passed at the :filters key get turned into the format
      # SurveyGizmo expects for its internal filtering.
      #
      # Properties from the conditions hash (e.g. survey_id) will be added to the returned objects
      def all(conditions = {})
        fail ':all_pages and :page are mutually exclusive' if conditions[:page] && conditions[:all_pages]
        logger.warn('Only retrieving first page of results!') unless conditions[:page] || conditions[:all_pages]

        all_pages = conditions.delete(:all_pages)
        conditions[:resultsperpage] ||= SurveyGizmo.configuration.results_per_page

        Enumerator.new do |yielder|
          response = nil

          while !response || (all_pages && response['page'] < response['total_pages'])
            conditions[:page] = response ? response['page'] + 1 : conditions.fetch(:page, 1)

            start_fetch_time = Time.now
            logger.debug("Fetching #{name} page #{conditions} - #{conditions[:page]}#{response ? "/#{response['total_pages']}" : ''}...")
            response = Connection.get(create_route(:create, conditions)).body
            collection = response['data'].map { |datum| datum.is_a?(Hash) ? new(conditions.merge(datum)) : datum }

            # Sub questions are not pulled by default so we have to retrieve them manually.  SurveyGizmo
            # claims they will fix this bug and eventually all questions will be returned in one request.
            question_class = SurveyGizmo.configuration.v5? ? SurveyGizmo::V5::Question : SurveyGizmo::V4::Question
            if self == question_class
              collection += collection.flat_map { |question| question.sub_questions }
            end

            logger.debug("  Fetched #{conditions[:resultsperpage]} of #{name} in #{(Time.now - start_fetch_time).to_i}s...")
            collection.each { |e| yielder.yield(e) }
          end
        end
      end

      # Retrieve a single resource.  See usage comment on .all
      def first(conditions = {})
        new(conditions.merge(Connection.get(create_route(:get, conditions)).body['data']))
      end

      # Create a new resource object locally and save to SurveyGizmo.  Returns the newly created Resource instance.
      def create(attributes = {})
        new(attributes).save
      end

      # Delete resources
      def destroy(conditions)
        Connection.delete(create_route(:delete, conditions))
      end

      # @route is either a hash to be used directly or a string from which standard routes will be built
      def routes
        fail "route not set in #{name}" unless @route
        return @route if @route.is_a?(Hash)

        routes = { create: @route }
        [:get, :update, :delete].each { |k| routes[k] = @route + '/:id' }
        routes
      end

      # Replaces the :page_id, :survey_id, etc strings defined in each model's routes with the
      # values in the params hash
      def create_route(method, params)
        fail "No route defined for #{method} on #{name}" unless routes[method]

        url_params = params.dup
        rest_path = routes[method].gsub(/:(\w+)/) do |m|
          fail SurveyGizmo::URLError, "Missing RESTful parameters in request: `#{m}`" unless url_params[$1.to_sym]
          url_params.delete($1.to_sym)
        end

        SurveyGizmo.configuration.api_version + rest_path + filters_to_query_string(url_params)
      end

      private

      # Convert a [Hash] of params and internal surveygizmo style filters into a query string
      #
      # The hashes at the :filters key get turned into URL params like:
      # # filter[field][0]=istestdata&filter[operator][0]=<>&filter[value][0]=1
      def filters_to_query_string(params = {})
        return '' unless params && params.size > 0

        params = params.dup
        url_params = {}

        Array.wrap(params.delete(:filters)).each_with_index do |filter, i|
          fail "Bad filter params: #{filter}" unless filter.is_a?(Hash) && [:field, :operator, :value].all? { |k| filter[k] }

          url_params["filter[field][#{i}]".to_sym]    = "#{filter[:field]}"
          url_params["filter[operator][#{i}]".to_sym] = "#{filter[:operator]}"
          url_params["filter[value][#{i}]".to_sym]    = "#{filter[:value]}"
        end

        uri = Addressable::URI.new(query_values: url_params.merge(params))
        "?#{uri.query}"
      end

      def logger
        SurveyGizmo.configuration.logger
      end
    end

    ### BELOW HERE ARE INSTANCE METHODS ###

    # If we have an id, it's an update because we already know the surveygizmo assigned id
    # Returns itself if successfully saved, but with attributes (like id) added by SurveyGizmo
    def save
      method, path = id ? [:post, :update] : [:put, :create]
      self.attributes = Connection.send(method, create_route(path), attributes_without_blanks).body['data']
      self
    end

    # Repopulate the attributes based on what is on SurveyGizmo's servers
    def reload
      self.attributes = Connection.get(create_route(:get)).body['data']
      self
    end

    # Delete the Resource from Survey Gizmo
    def destroy
      fail "No id; can't delete #{self.inspect}!" unless id
      Connection.delete(create_route(:delete))
    end

    def inspect
      attribute_strings = self.class.attribute_set.map do |attrib|
        value = self.send(attrib.name)
        value = value.is_a?(Hash) ? value.inspect : value.to_s
        "  \"#{attrib.name}\" => \"#{value}\"\n" unless value.strip.blank?
      end.compact

      "#<#{self.class.name}:#{self.object_id}>\n#{attribute_strings.join}"
    end

    private

    def attributes_without_blanks
      attributes.reject { |k, v| v.blank? }
    end

    # Extract attributes required for API calls about this object
    def route_params
      params = { id: id }

      self.class.routes.values.each do |route|
        route.gsub(/:(\w+)/) do |m|
          m = m.delete(':').to_sym
          params[m] = self.send(m)
        end
      end

      params
    end

    # Attributes that should be passed down the object hierarchy - e.g. a Question should have a survey_id
    # Also used for loading member objects, e.g. loading Options for a given Question.
    def children_params
      klass_id = self.class.name.split('::').last.downcase + '_id'
      route_params.merge(klass_id.to_sym => id).reject { |k, v| k == :id }
    end

    def create_route(method)
      self.class.create_route(method, route_params)
    end
  end
end
