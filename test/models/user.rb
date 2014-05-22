unless defined?(User)
  class User
    attr_accessor :age, :city, :name, :first, :float, :hobbies, :some_attr, :best_hobby

    DEFAULT_AGE      = 24
    DEFAULT_CITY     = 'irvine'
    DEFAULT_NAME     = 'rabl'
    DEFAULT_FIRST    = 'bob'
    DEFAULT_FLOAT    = 1234.56
    DEFAULT_HOBBIES  = ['Photography']
    DEFAULT_BEST_HOBBY = 'Reading'
    DEFAULT_SOME_ATTR = 'value'

    def initialize(attributes={})
      %w(age city name first float hobbies best_hobby some_attr).each do |attr|
        self.send "#{attr}=", (attributes.has_key?(attr.to_sym) ? attributes[attr.to_sym] : self.class.const_get("DEFAULT_#{attr.upcase}"))
      end
      self.hobbies = self.hobbies.map { |h| Hobby.new(h) }
      self.best_hobby = BestHobby.new(self.best_hobby)
    end
  end

  class Hobby
    attr_accessor :name
    def initialize(name); @name = name; end
  end

  class ModelName
    attr_accessor :element
    def initialize(element); @element = element; end
  end

  # test for camelizing
  class BestHobby < Hobby
    def self.model_name
      ModelName.new('best_hobby')
    end
  end
end

unless defined?(NestedScope::User)
  module NestedScope
    class User
      def controller; self; end
      def controller_name; self.class.name.downcase; end
    end
  end
end
