---
title: Ruby Mixin Exploration
date: 2013-03-20
categories:
  - Development
tags:
  - testing
  - ruby
  - rspec
  - rails
---

Recently I've been playing with Ruby's `class_eval` and `define_method` to
append methods to an object. Meta programming is something new for me and I had
a problem that would benefit from using some of Ruby's cool features.


## The Problem

There was a model that had 6 fields that needed to be generated at some point in
time. Some fields had to be unique and others had to be generated a bit
differently. Here is a contrived example of what I was doing:

```ruby
class User < ActiveRecord::Base
  def generate_api_token
    begin
      self.api_token = SecureRandom.urlsafe_base64(32)
    end while self.class.exists?(api_token: self.api_token)
    self.api_token
  end

  def generate_new_password
    self.password = SecureRandom.urlsafe_base64(16)
  end
end

class Widget < ActiveRecord::Base
  def generate_slug
    begin
      self.slug = SecureRandom.urlsafe_base64(32)
    end while self.class.exists?(slug: self.slug)
    self.slug
  end
end
```

If these generators are spread across multiple models, it will cloud the source
code and a test will need to be written for every generator. If we utilized
shared examples, there wouldn't be a need to write a test for every single
generator.


## The Goal

In the end, I wanted an easy to read DSL. Adding more DSL to a class can mean a
"_code smell_", however in this case, I do not think it is a code smell.

```ruby
# app/models/some_model.rb
class SomeModel < ActiveRecord::Base
  include Generatable

  generatable :some_field,   lambda { SecureRandom.hex(32) }
  generatable :unique_field, lambda { SecureRandom.hex(32) }, unique: true
end

s = SomeModel.new
s.generate_some_field #=> some 32 character string
s.generate_unique_field #=> some 32 character unique string
```

### The pros
  * Easy to read
  * Easy to figure out where `generatable` is being loaded from
  * Compact
  * Testing becomes easier (_more on this later_)

### The cons
  * Can't use the model in the lambda
  * Adds to model complexity
  * Lose some control on testing (_more on this later_)


## Solution

This is a perfect case where `ActiveSupport::Concern` applies. This is
functionality that multiple models can utilize and thus, should be put into a
mixin and included to those models. My initial implementation only made a simple
generator but, it does show how `class_eval` works and is an easy example to
grok.

```ruby
# app/models/concerns/generatable.rb
module Generatable
  extend ActiveSupport::Concern

  module ClassMethods
    # @param [String] field the name of the field you want to generate
    # @param [Proc] generator the lambda or Proc that you wish to use as the
    #   generator
    # @param [Hash] options
    # @option options :unique
    # @return [void]
    def generatable field, generator, options={}
      field = field.to_s
      class_eval do
        define_method "generate_#{field}" do
          self.send("#{field}=", generator.call)
        end
      end
    end
  end

end
```

The next requirement I had to fulfill was generating unique values. This took a
little bit more thought.

```ruby
# app/models/concerns/generatable.rb
module Generatable
  extend ActiveSupport::Concern

  module ClassMethods
    # @param [String] field the name of the field you want to generate
    # @param [Proc] generator the lambda or Proc that you wish to use as the
    #   generator
    # @param [Hash] options
    # @option options :unique
    # @return [void]
    def generatable field, generator, options={}
      field = field.to_s

      if options[:unique]
        class_eval do
          define_method "generate_#{field}" do
            begin
              self.send("#{field}=", generator.call)
            end while self.class.exists?(field.to_sym => self.send(field))
            self.send(field)
          end
        end
      else
        class_eval do
          define_method "generate_#{field}" do
            self.send("#{field}=", generator.call)
          end
        end
      end
    end
  end

end
```

This isn't exactly pretty. Infact, one could argue that this is a bit difficult
to follow due to the `if options[:unique]` statement. Another possible solution
could be to break this up into three methods like so:

```ruby
# app/models/concerns/generatable.rb
module Generatable
  extend ActiveSupport::Concern

  module ClassMethods
    # Appends a generator
    # @param [String] field the name of the field you want to generate
    # @param [Proc] generator the lambda or Proc that you wish to use as the
    #   generator
    # @param [Hash] options
    # @option options :unique
    # @return [void]
    def generatable field, generator, options={}
      if options[:unique]
        generatable_unique field, generator
      else
        generatable_simple field, generator
      end
    end

    # Append a unique generator
    # @param [String] field the name of the field you want to generate
    # @param [Proc] generator the lambda or Proc that you wish to use as the
    #   generator
    def generatable_unique field, generator
      field = field.to_s
      class_eval do
        define_method "generate_#{field}" do
          begin
            self.send("#{field}=", generator.call)
          end while self.class.exists?(field.to_sym => self.send(field))
          self.send(field)
        end
      end
    end

    # Append a simple generator
    # @param [String] field the name of the field you want to generate
    # @param [Proc] generator the lambda or Proc that you wish to use as the
    #   generator
    def generatable_simple field, generator
      field = field.to_s
      class_eval do
        define_method "generate_#{field}" do
          self.send("#{field}=", generator.call)
        end
      end
    end
  end

end
```

## Testing

Earlier I mentioned that this makes testig easier and then followed up with a
loss of control in the tests. The `Generatable` module will need to be tested in
some fashion, whether it is directly testing it via including it on a dummy
model or making a shared example where the test would have `it_behaves_like`
somewhere.

Testing a module directly:

```ruby
# Module Testing
module Say
  extend ActiveSupport::Concern
  def hello
    "hello"
  end
end

class DummyClass
  include Say
end

describe Say do
  let(:dummy_class) { DummyClass }
  let(:dummy) { dummy_class.new }

  it "get hello string" do
    dummy_class.hello.should == "hello"
  end
end
```

```ruby
# spec/support/shared_examples/generatable_fields.rb
shared_examples 'generatable fields' do |field|
  describe "#generate_#{field}" do
    subject { described_class.new }

    it "should change #{field}" do
      expect {
        subject.send("generate_#{field}")
      }.to change(subject, field.to_sym)
    end
  end
end
```

```ruby
# spec/models/user_spec.rb
describe User do
  include_examples 'generatable fields', :api_token
  include_examples 'generatable fields', :password
end
```

## Resources
  * [Put Chubby Models On A Diet With Concerns](http://37signals.com/svn/posts/3372-put-chubby-models-on-a-diet-with-concerns)
  * [Testing Modules in RSpec](http://stackoverflow.com/questions/1542945/testing-modules-in-rspec)
