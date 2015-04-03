require File.expand_path('../teststrap',   __FILE__)

context "Rabl::Builder with @rabl_hash" do
  helper(:scope)      { Object.new.tap { |o| o.instance_variable_set :@rabl_hash, true } }
  helper(:builder)    { |opt| Rabl::Builder.new(opt.merge scope: scope, rabl_hash: true) }
  helper(:build_hash) { |obj, opt| builder(opt.merge scope: scope, rabl_hash: true).build(obj) }

  setup do
    @users = [User.new.attributes, User.new.attributes]
    @user = User.new.attributes
    builder({:view_path => '/path/to/views'})
  end

  context "#initialize" do
    asserts_topic.assigns :options
    asserts_topic.assigns :_view_path
  end

  context "#build" do
    setup { b = builder({}); b.build(@user); b }
    asserts_topic.assigns :_object
    asserts_topic.assigns :_result
  end

  context "#to_hash" do
    context "when given a simple object" do
      setup { builder({ :attributes => { :name => {} } }) }
      asserts "that the object is set properly" do
        topic.build(@user, :root_name => "user")
      end.equivalent_to({ "user" => { "name" => "rabl" } })
    end

    context "when given an object alias" do
     setup { builder({ :attributes => { :name => { :as => :foo } } }) }
      asserts "that the object is set properly" do
        topic.build(@user.tap { |u| u['foo'] = u.delete('name') }, :root_name => "person")
      end.equivalent_to({ "person" => { "foo" => "rabl" } })
    end

    context "when specified with no root" do
      setup { builder({ :attributes => { :name => { :as => :name } } }) }
      asserts "that the object is set properly" do
        topic.build(@user, :root => false)
      end.equivalent_to({ "name" => "rabl" })
    end

    context "when nil values are replaced with empty strings" do
      setup do
        Rabl.configuration.replace_nil_values_with_empty_strings = true
        builder({ :attributes => { :name => {} } })
      end
      asserts "that an empty string is returned as the value" do
        topic.build(User.new(:name => nil).attributes)
      end.equivalent_to({ "name" => "" })
      teardown do
        Rabl.configuration.replace_nil_values_with_empty_strings = false
      end
    end

    context "when empty string values are replaced with nil values" do
      setup do
        Rabl.configuration.replace_empty_string_values_with_nil_values = true
        builder({ :attributes => { :name => {} } })
      end

      asserts "that nil is returned as the value" do
        topic.build(User.new(:name => "").attributes)
      end.equivalent_to({ "name" => nil })

      asserts "that it handles existing nil values correctly" do
        topic.build(User.new(:name => nil).attributes)
      end.equivalent_to({ "name" => nil })

      asserts "that it handles existing non nil values correctly" do
        topic.build(User.new(:name => 10).attributes)
      end.equivalent_to({ "name" => 10 })

      teardown do
        Rabl.configuration.replace_empty_string_values_with_nil_values = false
      end
    end

    context "when nil values are excluded" do
      setup do
        Rabl.configuration.exclude_nil_values = true
        builder({ :attributes => { :name => {} } })
      end
      asserts "that an nil attribute is not returned" do
        topic.build(User.new(:name => nil).attributes)
      end.equivalent_to({ })
      teardown do
        Rabl.configuration.exclude_nil_values = false
      end
    end
  end

  context "#attribute" do
    asserts "that the node" do
      build_hash @user, :attributes => { :name => {}, :city => { :as => :city } }
    end.equivalent_to({"name" => 'rabl', "city" => 'irvine'})

    context "that with a non-existent attribute" do
      context "when non-existent attributes are allowed by the configuration" do
        setup { stub(Rabl.configuration).raise_on_missing_attribute { false } }

        asserts "the node" do
          build_hash @user, :attributes => { :fake => {as: :fake} }
        end.equals({})
      end

      context "when non-existent attributes are forbidden by the configuration" do
        setup { stub(Rabl.configuration).raise_on_missing_attribute { true } }

        asserts "the node" do
          build_hash @user, :attributes => { :fake => {as: :fake} }
        end.raises_kind_of(RuntimeError)
      end
    end

    context "that with a string key" do
      setup { builder({ :attributes => { "name" => {} } }) }
      asserts "the node name is converted to a symbol" do
        topic.build(@user, :name => "user")
      end.equivalent_to({ "name" => "rabl" })
    end

    context "that with the same node names as strings and symbols" do
      setup { builder({ :attributes => { "name" => {}, :name => {} } }) }
      asserts "the nodes aren't duplicated" do
        topic.build(@user, :name => "user")
      end.equivalent_to({ "name" => "rabl" })
    end
  end

  context "#allowed_attribute" do
    helper(:default_attributes) { { :allowed_attributes => { :name => {}, :city => { :as => :city } } } }

    context "when not filtered" do
      setup { builder(default_attributes) }

      asserts "shows nothing" do
        topic.build(@user)
      end.equivalent_to({})
    end

    context "when not filtered but has default attributes" do
      setup { builder(default_attributes.merge(:attributes => { :age => {} })) }

      asserts "shows only defaults" do
        topic.build(@user)
      end.equivalent_to({ "age" => 24 })
    end

    context "symbolized keys" do
      setup { builder(default_attributes.merge(:filters => { 'name' => {} })) }

      asserts "restrict nodes in custom mode" do
        topic.build(@user)
      end.equivalent_to({"name" => 'rabl'})
    end

    context "ignores non-existent filtered attribute" do
      setup { stub(Rabl.configuration).raise_on_missing_attribute { false } }

      context "when not allowed" do
        setup { builder(default_attributes.merge(:filters => { 'is_admin' => {} })) }

        asserts "silently pass" do
          topic.build(@user)
        end.equals({})
      end

      context "when not exist" do
        setup { builder(default_attributes.merge(:filters => { 'password' => {} })) }

        asserts "silently pass" do
          topic.build(@user)
        end.equals({})
      end
    end

    context "when confirured to raise" do
      setup { stub(Rabl.configuration).raise_on_missing_attribute { true } }

      context "when not exist" do
        asserts "raises Error" do
          builder(default_attributes.merge(:filters => { 'password' => {} })).build(@user)
        end.raises_kind_of(RuntimeError)
      end
    end
  end

  context "#node" do
    asserts "that it has node :foo" do
      build_hash @user, :node => [{ :name => :foo, :options => {}, :block => lambda { |u| "bar" } }]
    end.equivalent_to({"foo" => 'bar'})

    asserts "that using object it has node :boo" do
      build_hash @user, :node => [
        { :name => :foo, :options => {}, :block => lambda { |u| "bar" } },
        { :name => :baz, :options => {}, :block => lambda { |u| u['city'] } }
      ]
    end.equivalent_to({"foo" => 'bar', "baz" => 'irvine'})

    asserts "that it converts the node name to a symbol" do
      build_hash @user, :node => [{ :name => "foo", :options => {}, :block => lambda { |u| "bar" } }]
    end.equivalent_to({"foo" => 'bar'})

    asserts "that the same node names as a string and symbol aren't duplicated" do
      build_hash @user, :node => [
        { :name => "foo", :options => {}, :block => lambda { |u| "bar" } },
        { :name => :foo, :options => {}, :block => lambda { |u| "bar" } }
      ]
    end.equivalent_to({"foo" => 'bar'})
  end

  context "#child" do
    asserts "that it generates if no data present" do
      builder(:child => []).build(@user)
    end.equals({})

    asserts "that it generates with a hash" do
      b = builder(:child => [ { :data => { @user => :user }, :options => { }, :block => lambda { |u| attribute :name } } ])
      b.build(@user)
    end.equivalent_to({ "user" => { "name" => "rabl" } })

    asserts "that it generates with a hash alias" do
      b = builder :child => [{ :data => { @user => :person }, :options => {}, :block => lambda { |u| attribute :name } }]
      b.build(@user)
    end.equivalent_to({ "person" => { "name" => "rabl" } })

    asserts "that it generates with an object" do
      b = builder :child => [{ :data => @user, :options => {}, :block => lambda { |u| attribute :name } }]
      mock(b).data_name(@user) { :user }
      mock(b).object_to_hash(@user, { :root => false, :rabl_hash => true, parent_object: @user }).returns('xyz').subject
      b.build(@user)
    end.equivalent_to({ "user" => 'xyz'})

    asserts "that it generates with an collection and child_root" do
      b = builder :child => [{ :data => @users, :options => {}, :block => lambda { |u| attribute :name } }], :child_root => true
      mock(b).data_name(@users) { :users }
      mock(b).object_to_hash(@users, { :root => true, :rabl_hash => true, :child_root => true, parent_object: @user }).returns('xyz').subject
      b.build(@user)
    end.equivalent_to({ "users" => 'xyz'})

    asserts "that it generates with an collection and no child root" do
      b = builder :child => [{ :data => @users, :options => {}, :block => lambda { |u| attribute :name } }], :child_root => false
      mock(b).data_name(@users) { :users }
      mock(b).object_to_hash(@users, { :root => false, :rabl_hash => true, :child_root => false, parent_object: @user }).returns('xyz').subject
      b.build(@user)
    end.equivalent_to({ "users" => 'xyz' })

    asserts "that it generates with an collection and a specified object_root_name and root" do
      ops = { :object_root => "person", :root => :people }
      b = builder :child => [{ :data => @users, :options => ops, :block => lambda { |u| attribute :name } }], :child_root => true
      mock(b).object_to_hash(@users, { :root => "person", :object_root_name => "person", :rabl_hash => true, :child_root => true, parent_object: @user }).returns('xyz').subject
      b.build(@user)
    end.equivalent_to({ "people" => 'xyz' })

    asserts "that it converts the child name to a symbol" do
      b = builder(:child => [ { :data => { @user => "user" }, :options => { }, :block => lambda { |u| attribute :name } } ])
      b.build(@user)
    end.equivalent_to({ "user" => { "name" => "rabl" } })

    asserts "that it does't duplicate childs with the same name as a string and symbol" do
      b = builder(:child => [
        { :data => { @user => "user" }, :options => { }, :block => lambda { |u| attribute :name } },
        { :data => { @user => :user }, :options => { }, :block => lambda { |u| attribute :name } }
      ])
      b.build(@user)
    end.equivalent_to({ "user" => { "name" => "rabl" } })
  end

  context "#allowed_child" do
    asserts "that it not disturbs simple child" do
      b = builder(
        :child => [ {
          :data => { @user => :user },
          :options => { },
          :block => lambda { |u| attribute :name }
        } ],
        :allowed_child => [ {
          :data => { @user => :user },
          :options => { },
          :block => lambda { |u| attribute :email }
        } ]
      )
      b.build(@user)
    end.equivalent_to({ "user" => { "name" => "rabl" } })

    asserts "that it prefers allowed_child over simple child && filters it" do
      b = builder(
        :child => [ {
          :data => { @user => :user },
          :options => { },
          :block => lambda { |u| attribute :name }
        } ],
        :allowed_child => [ {
          :data => { @user => :user },
          :options => { },
          :block => lambda { |u| attribute :age, :city }
        } ],
        :filters => { 'user' => { 'age' => {} } }
      )
      b.build(@user)
    end.equivalent_to({ "user" => { "age" => 24, "city" => 'irvine' } })

    asserts "that it prefers uses all attributes from allowed_child when filter empty" do
      b = builder(
        :child => [ {
          :data => { @user => :user },
          :options => { },
          :block => lambda { |u| attribute :name }
        } ],
        :allowed_child => [ {
          :data => { @user => :user },
          :options => { },
          :block => lambda { |u| attribute :age, :city }
        } ],
        :filters => { 'user' => {} }
      )
      b.build(@user)
    end.equivalent_to({ "user" => { "age" => 24, "city" => 'irvine' } })
  end

  context "#glue" do
    asserts "that it generates if no data present" do
      builder(:glue => []).build(@user)
    end.equals({})

    asserts "that it generates the glue attributes" do
      b = builder :glue => [{ :data => @user, :options => {}, :block => lambda { |u| attribute :name }}]
      mock(b).object_to_hash(@user, { :root => false }).returns({"user" => 'xyz'}).subject
      b.build(@user)
    end.equivalent_to({ "user" => 'xyz' })

    asserts "that it appends the glue attributes to result" do
      b = builder :glue => [{ :data => @user, :options => {}, :block => lambda { |u| attribute :name => :user_name }}]
      b.build(@user.tap { |u| u['user_name'] = u.delete('name') })
    end.equivalent_to({ "user_name" => 'rabl' })

    asserts "that it does not generate new attributes if no glue attributes are present" do
      b = builder :glue => [{ :data => @user, :options => {}, :block => lambda { |u| attribute :name }}]
      mock(b).object_to_hash(@user,{ :root => false }).returns({}).subject
      b.build(@user)
    end.equals({})
  end

  context "#extend" do
    asserts "that it does not genereate if no data is present" do
      b = builder :extends => [{ :file => 'users/show', :options => {}, :block => lambda { |u| attribute :name  }}]
      mock(b).partial('users/show',{ :object => @user }).returns({}).subject
      b.build(@user)
    end.equals({})

    asserts "that it generates if data is present" do
      b = builder :extends => [{ :file => 'users/show', :options => {}, :block => lambda { |u| attribute :name  }}]
      mock(b).partial('users/show', { :object => @user }).returns({"user" => 'xyz'}).subject
      b.build(@user)
    end.equivalent_to({"user" => 'xyz'})

    asserts "that it generates if local data is present but object is false" do
      b = builder :extends => [{ :file => 'users/show', :options => { :object => @user }, :block => lambda { |u| attribute :name  }}]
      mock(b).partial('users/show', { :object => @user }).returns({"user" => 'xyz'}).subject
      b.build(false)
    end.equivalent_to({"user" => 'xyz'})
  end

  context "#resolve_conditionals" do
    class ArbObj
      def cool?
        false
      end

      def smooth?
        true
      end
    end

    asserts "that it can use symbols on if condition and return false if method returns false" do
      scope = Rabl::Builder.new
      scope.instance_variable_set(:@_object, ArbObj.new)
      scope.send(:resolve_condition, { :if => :cool? })
    end.equals(false)

    asserts "that it can use symbols on if condition and return true if method returns true" do
      scope = Rabl::Builder.new
      scope.instance_variable_set(:@_object, ArbObj.new)
      scope.send :resolve_condition, { :if => :smooth? }
    end.equals(true)

    asserts "that it can use symbols as unless condition and return true if method returns false" do
      scope = Rabl::Builder.new
      scope.instance_variable_set(:@_object, ArbObj.new)
      scope.send :resolve_condition, { :unless => :cool? }
    end.equals(true)

    asserts "that it can use symbols as unmless condition and return false if method returns true" do
      scope = Rabl::Builder.new
      scope.instance_variable_set(:@_object, ArbObj.new)
      scope.send :resolve_condition, { :unless => :smooth? }
    end.equals(false)
  end
end

