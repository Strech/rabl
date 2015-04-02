require 'active_support/inflector' # for the sake of pluralizing

module Rabl
  module Helpers
    # Set of class names known to be objects, not collections
    KNOWN_OBJECT_CLASSES = ['Struct']

    def rabl_hash?
      !!(@rabl_hash || (@options && @options[:scope].instance_variable_get(:@rabl_hash)))
    end

    def complex_data?(data)
      data.is_a?(Hash) && data.keys.size == 1 && !data.keys[0].is_a?(Symbol)
    end

    def alias_link?(data)
      data.is_a?(Hash) && data.keys.size == 1 && data.keys[0].is_a?(Symbol) &&
        data.values[0].is_a?(Symbol)
    end

    def rendered_in_rabl?(data)
      return false unless data.keys[0].is_a?(Hash)
      data.keys[0].keys.size == 1 && data.keys[0].keys[0].to_s == data.values[0].to_s
    end

    # data_object(data) => <AR Object>
    # data_object(@user => :person) => @user
    # data_object(:user => :person) => @_object.send(:user)
    def data_object(data)
      if rabl_hash? && complex_data?(data)
        # {{"deal" => {"title" => ""}} => "deal"}
        if rendered_in_rabl?(data)
          return data.keys[0][data.values[0].to_s]
        else
          return data.keys[0]
        end
      end

      data = if (data.is_a?(Hash) && data.keys.size == 1)
        (rabl_hash? && alias_link?(data)) ? data.values.first : data.keys.first
      else
        data
      end

      if data.is_a?(Symbol) && defined?(@_object) && @_object
        rabl_hash? ? @_object[data.to_s] : @_object.__send__(data)
      else
        data
      end
    end

    # data_object_attribute(data) => @_object.send(data)
    def data_object_attribute(data)
      output = if rabl_hash?
        @_object.respond_to?(:key?) ? @_object[data.to_s] : @_object[1]
      else
        @_object.__send__(data)
      end

      escape_output output
    end

    # data_name(data) => "user"
    # data_name(@user => :person) => :person
    # data_name(@users) => :user
    # data_name([@user]) => "users"
    # data_name([]) => "array"
    def data_name(data_token)
      return unless data_token # nil or false
      return data_token.values.first if data_token.is_a?(Hash) # @user => :user
      data = data_object(data_token)

      if is_collection?(data) # data is a collection
        return data_token.to_s.pluralize if data_token.is_a?(Symbol) && rabl_hash?

        object_name = data.table_name if data.respond_to?(:table_name)
        if !object_name && data.respond_to?(:first)
          first = data.first
          object_name = data_name(first).to_s.pluralize if first.present?
        end
        object_name ||= data_token if data_token.is_a?(Symbol)
        object_name
      elsif is_object?(data) # data is an object
        return data_token if data_token.is_a?(Symbol) && rabl_hash?

        object_name = object_root_name if object_root_name
        object_name ||= data if data.is_a?(Symbol)
        object_name ||= collection_root_name.to_s.singularize if collection_root_name
        object_name ||= data.class.respond_to?(:model_name) ? data.class.model_name.element : data.class.to_s.downcase
        object_name
      else
        data_token
      end
    end

    # Returns the object rootname based on if the root should be included
    # Can be called with data as a collection or object
    # determine_object_root(@user, :user, true) => "user"
    # determine_object_root(@user, :person) => "person"
    # determine_object_root([@user, @user]) => "user"
    def determine_object_root(data_token, data_name=nil, include_root=true)
      return if object_root_name == false
      root_name = data_name.to_s if include_root
      if is_object?(data_token) || data_token.nil?
        root_name
      elsif is_collection?(data_token)
        object_root_name || (root_name.singularize if root_name)
      end
    end

    # Returns true if obj is not a collection
    # is_object?(@user) => true
    # is_object?([]) => false
    # is_object?({}) => false
    def is_object?(obj)
      if rabl_hash?
        obj && (obj.is_a?(Hash) ||
         (KNOWN_OBJECT_CLASSES & obj.class.ancestors.map(&:name)).any?)
      else
        obj && (!data_object(obj).respond_to?(:map) || !data_object(obj).respond_to?(:each) ||
         (KNOWN_OBJECT_CLASSES & obj.class.ancestors.map(&:name)).any?)
      end
    end

    # Returns true if the obj is a collection of items
    # is_collection?(@user) => false
    # is_collection?([]) => true
    def is_collection?(obj)
      if rabl_hash?
        obj && data_object(obj).is_a?(Array) &&
          (KNOWN_OBJECT_CLASSES & obj.class.ancestors.map(&:name)).empty?
      else
        obj && data_object(obj).respond_to?(:map) && data_object(obj).respond_to?(:each) &&
          (KNOWN_OBJECT_CLASSES & obj.class.ancestors.map(&:name)).empty?
      end
    end

    # Returns the scope wrapping this engine, used for retrieving data, invoking methods, etc
    # In Rails, this is the controller and in Padrino this is the request context
    def context_scope
      defined?(@_scope) ? @_scope : nil
    end

    # Returns the root (if any) name for an object within a collection
    # Sets the name of the object i.e "person"
    # => { "users" : [{ "person" : {} }] }
    def object_root_name
      defined?(@_object_root_name) ? @_object_root_name : nil
    end

    # Returns the root for the collection
    # Sets the name of the collection i.e "people"
    #  => { "people" : [] }
    def collection_root_name
      defined?(@_collection_name) ? @_collection_name : nil
    end

    # Returns true if the value is a name value (symbol or string)
    def is_name_value?(val)
      val.is_a?(String) || val.is_a?(Symbol)
    end

    # Fetches a key from the cache and stores rabl template result otherwise
    # fetch_from_cache('some_key') { ...rabl template result... }
    def fetch_result_from_cache(cache_key, cache_options=nil, &block)
      expanded_cache_key = ActiveSupport::Cache.expand_cache_key(cache_key, :rabl)
      Rabl.configuration.cache_engine.fetch(expanded_cache_key, cache_options, &block)
    end

    # Returns true if the cache has been enabled for the application
    def template_cache_configured?
      if defined?(Rails)
        defined?(ActionController::Base) && ActionController::Base.perform_caching
      else
        Rabl.configuration.perform_caching
      end
    end

    # Escape output if configured and supported
    def escape_output(data)
      (data && defined?(ERB::Util.h) && Rabl.configuration.escape_all_output) ? ERB::Util.h(data) : data
    end

  end
end

