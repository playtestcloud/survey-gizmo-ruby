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

      # @route is either a hash to be used directly or a string from which standard routes will be built
      def routes
        fail "route not set in #{name}" unless @route
        return @route if @route.is_a?(Hash)

        routes = { create: @route }
        [:get, :update, :delete].each { |k| routes[k] = @route + '/:id' }
        routes
      end
    end

    ### BELOW HERE ARE INSTANCE METHODS ###

    # If we have an id, it's an update because we already know the surveygizmo assigned id
    # Returns itself if successfully saved, but with attributes (like id) added by SurveyGizmo
    def save
      method, path = id ? [:post, :update] : [:put, :create]
      self.attributes = @client.send(
        method,
        create_route(path),
        attributes_without_blanks
      ).body['data']
      self
    end

    # Repopulate the attributes based on what is on SurveyGizmo's servers
    def reload
      self.attributes = @client.get(create_route(:get)).body['data']
      self
    end

    # Delete the Resource from Survey Gizmo
    def destroy
      fail "No id; can't delete #{self.inspect}!" unless id
      @client.delete(create_route(:delete))
    end

    def inspect
      attribute_strings = self.class.attribute_set.map do |attrib|
        value = send(attrib.name)
        value = value.is_a?(Hash) ? value.inspect : value.to_s
        "  \"#{attrib.name}\" => \"#{value}\"\n" unless value.strip.blank?
      end.compact

      "#<#{self.class.name}:#{self.object_id}>\n#{attribute_strings.join}"
    end

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
      self.class.create_route(@client, method, route_params)
    end
  end
end
