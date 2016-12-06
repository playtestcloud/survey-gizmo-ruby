module SurveyGizmo
  class ResourceClient
    def initialize(client, resource_class)
      @client = client
      @resource_class = resource_class
    end


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
      @client.warn('Only retrieving first page of results!') unless conditions[:page] || conditions[:all_pages]

      all_pages = conditions.delete(:all_pages)
      conditions[:resultsperpage] ||= @client.configuration.results_per_page

      Enumerator.new do |yielder|
        response = nil

        while !response || (all_pages && response['page'] < response['total_pages'])
          conditions[:page] = response ? response['page'] + 1 : conditions.fetch(:page, 1)

          start_fetch_time = Time.now
          @client.debug("Fetching #{@resource_class.name} page #{conditions} - #{conditions[:page]}#{response ? "/#{response['total_pages']}" : ''}...")
          response = @client.get(create_route(:create, conditions)).body
          collection = response['data'].map do |datum|
            datum.is_a?(Hash) ? new_with_client(conditions.merge(datum)) : datum
          end

          # Sub questions are not pulled by default so we have to retrieve them manually.  SurveyGizmo
          # claims they will fix this bug and eventually all questions will be returned in one request.
          if @resource_class == SurveyGizmo::API::Question
            collection += collection.flat_map { |question| question.sub_questions }
          end

          @client.debug("  Fetched #{conditions[:resultsperpage]} of #{@resource_class.name} in #{(Time.now - start_fetch_time).to_i}s...")
          collection.each { |e| yielder.yield(e) }
        end
      end
    end

    def new_with_client(*args)
      instance = @resource_class.new(*args)
      instance.instance_variable_set(:@client, @client)
      instance
    end

    # Retrieve a single resource.  See usage comment on .all
    def first(conditions = {})
      new_with_client(
        conditions.merge(
          @client.get(
            create_route(:get, conditions)
          ).body['data']
        )
      )
    end

    # Create a new resource object locally and save to SurveyGizmo.  Returns the newly created Resource instance.
    def create(attributes = {})
      new_with_client(attributes).save
    end

    # Delete resources
    def destroy(conditions)
      @client.delete(create_route(:delete, conditions))
    end

    # Replaces the :page_id, :survey_id, etc strings defined in each model's routes with the
    # values in the params hash
    def create_route(method, params)
      fail "No route defined for #{method} on #{@resource_class.name}" unless @resource_class.routes[method]

      url_params = params.dup
      rest_path = @resource_class.routes[method].gsub(/:(\w+)/) do |m|
        fail SurveyGizmo::URLError, "Missing RESTful parameters in request: `#{m}`" unless url_params[$1.to_sym]
        url_params.delete($1.to_sym)
      end

      @client.configuration.api_version + rest_path + filters_to_query_string(url_params)
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
  end
end
