module Rails
  module Generators
    class ParamsDeserializerGenerator < NamedBase
      source_root File.expand_path('../templates', __FILE__)
      check_class_collision suffix: 'ParamsDeserializer'

      argument :attributes, type: :array, default: [], banner: 'field field'

      def create_serializer_file
        template 'deserializer.rb.erb', File.join('app/deserializers', class_path, "#{file_name}_params_deserializer.rb")
      end

      private

      def attributes_names
        attributes.map! { |a| a.name.to_sym }
      end

      def parent_class_name
        'ParamsDeserializer'
      end
    end
  end
end
