require 'rails/generators'
require 'rails/generators/rails/resource/resource_generator'

module Rails
  module Generators
    class ResourceGenerator
      hook_for :params_deserializer, default: true, type: :boolean
    end
  end
end
