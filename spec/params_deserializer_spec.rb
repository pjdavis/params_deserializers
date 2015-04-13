require_relative '../lib/params_deserializer'

describe ParamsDeserializer do
  describe 'basic' do
    subject do
      Class.new(ParamsDeserializer) do
        attributes :id, :name
      end
    end

    let(:params) do
      { id: 5, name: 'foo' }
    end

    it 'copies an old param to a new param' do
      new_params = subject.new(params).deserialize
      expect(new_params[:id]).to eql(params[:id])
      expect(new_params[:name]).to eql(params[:name])
    end
  end

  describe 'overrides' do
    subject do
      Class.new(ParamsDeserializer) do
        attributes :foo
        def foo; 'bar'; end
      end
    end

    it 'allows method access for params?' do
      instance = subject.new({foo: 'baz'})
      new_params = instance.deserialize

      expect(new_params[:foo]).to eql('bar')
    end
  end

  describe 'overrides with context' do
    subject do
      Class.new(ParamsDeserializer) do
        attributes :foo
        def foo; params[:foo] << 'baz'; end
      end
    end

    it 'allows methods to access params' do
      instance = subject.new({foo: 'bar'})
      new_params = instance.deserialize

      expect(new_params[:foo]).to eql('barbaz')
    end
  end

  describe 'single attribute' do
    subject do
      Class.new(ParamsDeserializer) do
        def corge; 'grault'; end
        attribute :foo, rename_to: :foo_bar
        attributes :quux, :corge
      end
    end

    it 'copies an old param to a new param' do
      new_params = subject.new({ quux: 'corge' }).deserialize
      expect(new_params[:quux]).to eql('corge')
    end

    it 'allows an attribute to be renamed' do
      new_params = subject.new({ foo: 'baz' }).deserialize

      expect(new_params[:foo_bar]).to eql('baz')
      expect(new_params[:foo]).to be_nil
    end

    it 'does not overwrite an existing override method when defining a getter after the override method has been defined' do
      new_params = subject.new({ corge: 'garply' }).deserialize
      expect(new_params[:corge]).to eql('grault')
    end

    it 'creates and calls the pre-rename method' do
      deserializer = subject.new({ foo: 'baz' })
      expect(deserializer).to receive(:foo)
      expect(deserializer).to_not respond_to(:foo_bar)
      deserializer.deserialize
    end
  end

  describe 'has_many' do
    context 'with overrides' do
      subject do
        Class.new(ParamsDeserializer) do
          has_many :foos, rename_to: :foos_attributes
        end
      end

      it 'puts the new key in to new_params' do
        instance = subject.new(foos: [{bar: 1}])
        new_params = instance.deserialize

        expect(new_params[:foos_attributes]).to eql([{ bar: 1 }])
      end
    end

    context 'without overrides' do
      subject do
        Class.new(ParamsDeserializer) do
          has_many :foos
        end
      end

      it 'defaults to the key provided' do
        instance = subject.new(foos: [{bar: 1}])
        new_params = instance.deserialize

        expect(new_params[:foos]).to eql([{ bar:  1 }])
      end
    end

    context 'with an each_deserializer' do
      subject do
        foo_deserializer = Class.new(ParamsDeserializer) do
          attributes :baz
        end

        Class.new(ParamsDeserializer) do
          has_many :foos, each_deserializer: foo_deserializer
        end
      end

      it 'uses a provided each_deserializer for each item in a has_many relationship' do
        instance = subject.new(foos: [{ bar: 1, baz: 2},
                                      { bar: 3, baz: 4 }])
        new_params = instance.deserialize

        expect(new_params[:foos]).to eql([{ baz: 2 }, { baz: 4 }])
      end
    end
  end

  describe 'formatting keys' do
    describe 'with no format option passed in' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :camelCase
        end
      end

      it 'does not transform key case' do
        new_params = subject.new(camelCase: 'foo').deserialize
        expect(new_params[:camelCase]).to eql('foo')
        expect(new_params[:CamelCase]).to be_nil
        expect(new_params[:camel_case]).to be_nil
      end
    end

    describe 'snake_case' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :camelCase
          format_keys :snake_case
        end
      end

      it 'transforms all keys to snake_case' do
        new_params = subject.new(camelCase: 'foo').deserialize
        expect(new_params[:camel_case]).to eql('foo')
        expect(new_params[:camelCase]).to be_nil
      end
    end

    describe 'CamelCase' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :snake_case
          format_keys :camel_case
        end
      end

      it 'transforms all keys to CamelCase' do
        new_params = subject.new(snake_case: 'foo').deserialize
        expect(new_params[:SnakeCase]).to eql('foo')
        expect(new_params[:snake_case]).to be_nil
      end
    end

    describe 'lowerCamel' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :snake_case
          format_keys :lower_camel
        end
      end

      it 'transforms all keys to lowerCamel' do
        new_params = subject.new(snake_case: 'foo').deserialize
        expect(new_params[:snakeCase]).to eql('foo')
        expect(new_params[:snake_case]).to be_nil
      end
    end
  end

  context 'with a root key' do
    it 'keeps the root key by default' do
      deserializer = Class.new(ParamsDeserializer) do
        root :foo
        attributes :bar
      end
      new_params = deserializer.new(foo: { bar: 'baz' }).deserialize

      expect(new_params[:foo][:bar]).to eql('baz')
    end

    it 'discards the root key when the discard option is true' do
      deserializer = Class.new(ParamsDeserializer) do
        root :foo, discard: true
        attributes :bar
      end
      new_params = deserializer.new(foo: { bar: 'baz' }).deserialize

      expect(new_params[:foo]).to be_nil
      expect(new_params[:bar]).to eql('baz')
    end
  end

  describe 'present_if' do
    context 'without present_if' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :id, :name
        end
      end

      let(:params) do
        { id: 5, name: 'foo' }
      end

      it 'leaves undefined params undefined' do
        params.delete(:name)
        new_params = subject.new(params).deserialize
        expect(new_params).to_not have_key :name
      end

      it 'leaves nil params nil' do
        params[:name] = nil
        new_params = subject.new(params).deserialize
        expect(new_params).to have_key :name
        expect(new_params[:name]).to be_nil
      end
    end

    context 'with present_if' do
      subject do
        Class.new(ParamsDeserializer) do
          attributes :id
          attribute :name, present_if: -> { true }
          attribute :age, present_if: -> { params[:bar] == 'baz' }
          def name; 'foo'; end
        end
      end

      let(:params) do
        { id: 5 }
      end

      it 'allows deserialization of a param that does not exist' do
        new_params = subject.new(params).deserialize
        expect(new_params[:id]).to eql(params[:id])
        expect(new_params[:name]).to eql('foo')
      end

      it 'uses the present_if proc to determine whether a key should be present' do
        params[:bar] = 'baz'
        params[:age] = 25
        new_params = subject.new(params).deserialize
        expect(new_params[:age]).to eql(25)

        params[:bar] = 'quux'
        new_params = subject.new(params).deserialize
        expect(new_params).to_not have_key :age
      end
    end
  end
end
