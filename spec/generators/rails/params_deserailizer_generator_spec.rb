require "generator_spec"
require_relative '../../../lib/generators/rails/params_deserializer_generator'
describe "Rails::Generators::ParamsDeserializerGenerator", type: :generator do
  tests Rails::Generators::ParamsDeserializerGenerator
  destination File.expand_path("../../tmp", __FILE__)
  arguments %w(User birthday)

  before(:each) do
    prepare_destination
    run_generator
  end

  after(:each) do
    remove_entry_secure(destination_root)
  end

  it "creates a user deserializer" do
    expect(destination_root).to have_structure {
      directory "app" do
        directory "deserializers" do
          file "user_params_deserializer.rb" do
            contains "UserParamsDeserializer < ParamsDeserializer"
          end
        end
      end
    }
  end
end
