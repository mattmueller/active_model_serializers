class ActiveModel::Serializer::Adapter::JsonApi < ActiveModel::Serializer::Adapter
        extend ActiveSupport::Autoload
        autoload :PaginationLinks
        autoload :FragmentCache

        def initialize(serializer, options = {})
          super
          @hash = { data: [] }

          @included = ActiveModel::Serializer::Utils.include_args_to_hash(@options[:include])
          fields = options.delete(:fields)
          if fields
            @fieldset = ActiveModel::Serializer::Fieldset.new(fields, serializer.json_key)
          else
            @fieldset = options[:fieldset]
          end
        end

        def serializable_hash(options = nil)
          options ||= {}
          if serializer.respond_to?(:each)
            serializer.each do |s|
              result = self.class.new(s, @options.merge(fieldset: @fieldset)).serializable_hash(options)
              @hash[:data] << result[:data]

              if result[:included]
                @hash[:included] ||= []
                @hash[:included] |= result[:included]
              end
            end

            add_links(options)
          else
            primary_data = primary_data_for(serializer, options)
            relationships = relationships_for(serializer)
            included = included_for(serializer)
            @hash[:data] = primary_data
            @hash[:data][:relationships] = relationships if relationships.any?
            @hash[:included] = included if included.any?
          end
          @hash
        end

        def fragment_cache(cached_hash, non_cached_hash)
          root = false if @options.include?(:include)
          ActiveModel::Serializer::Adapter::JsonApi::FragmentCache.new().fragment_cache(root, cached_hash, non_cached_hash)
        end

        private

        def resource_identifier_type_for(serializer)
          if ActiveModel::Serializer.config.jsonapi_resource_type == :singular
            serializer.object.class.model_name.singular
          else
            serializer.object.class.model_name.plural
          end
        end

        def add_relationships(resource, name, serializers)
          resource[:relationships] ||= {}
          resource[:relationships][name] ||= { data: [] }
          resource[:relationships][name][:data] += serializers.map { |serializer| { type: serializer.json_api_type, id: serializer.id.to_s } }
        end

        def resource_identifier_id_for(serializer)
          if serializer.respond_to?(:id)
            serializer.id
          else
            serializer.object.id
          end
        end

        def resource_identifier_for(serializer)
          type = resource_identifier_type_for(serializer)
          id   = resource_identifier_id_for(serializer)

          { id: id.to_s, type: type }
        end

        def resource_object_for(serializer, options = {})
          options[:fields] = @fieldset && @fieldset.fields_for(serializer)

          cache_check(serializer) do
            result = resource_identifier_for(serializer)
            attributes = serializer.attributes(options).except(:id)
            result[:attributes] = attributes if attributes.any?
            result
          end
        end

        def primary_data_for(serializer, options)
          if serializer.respond_to?(:each)
            serializer.map { |s| resource_object_for(s, options) }
          else
            resource_object_for(serializer, options)
          end
        end

        def relationship_value_for(serializer, options = {})
          if serializer.respond_to?(:each)
            serializer.map { |s| resource_identifier_for(s) }
          else
            if options[:virtual_value]
              options[:virtual_value]
            elsif serializer && serializer.object
              resource_identifier_for(serializer)
            end
          end
        end

        def relationships_for(serializer)
          Hash[serializer.associations.map { |association| [association.key, { data: relationship_value_for(association.serializer, association.options) }] }]
        end

        def included_for(serializer)
          included = @included.flat_map do |inc|
            association = serializer.associations.find { |assoc| assoc.key == inc.first }
            _included_for(association.serializer, inc.second) if association
          end

          included.uniq
        end

        def _included_for(serializer, includes)
          if serializer.respond_to?(:each)
            serializer.flat_map { |s| _included_for(s, includes) }.uniq
          else
            return [] unless serializer && serializer.object

            primary_data = primary_data_for(serializer, @options)
            relationships = relationships_for(serializer)
            primary_data[:relationships] = relationships if relationships.any?

            included = [primary_data]

            includes.each do |inc|
              association = serializer.associations.find { |assoc| assoc.key == inc.first }
              if association
                included.concat(_included_for(association.serializer, inc.second))
                included.uniq!
              end
            end

            included
          end
        end

        def add_links(options)
          links = @hash.fetch(:links) { {} }
          collection = serializer.object
          @hash[:links] = add_pagination_links(links, collection, options) if paginated?(collection)
        end

        def add_pagination_links(links, resources, options)
          pagination_links = ActiveModel::Serializer::Adapter::JsonApi::PaginationLinks.new(resources, options[:context]).serializable_hash(options)
          links.update(pagination_links)
        end

        def paginated?(collection)
          collection.respond_to?(:current_page) &&
            collection.respond_to?(:total_pages) &&
            collection.respond_to?(:size)
        end
end
