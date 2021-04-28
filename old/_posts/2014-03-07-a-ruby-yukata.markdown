---
layout: post
title: A Ruby Yukata
date: 2014-03-07 12:00:00 -0600
comments: false
sharing: false
categories:
  - ruby
---

Let me introduce you to my new library called [Yukata][yukata]. It is a light
weight Ruby attribute library that is configurable and extendable.

[Virtus][virtus] has been a huge inspiration for this library. I enjoyed the DSL
it offered, while allowing me to have a quick way to make data objects.

Here is an example on how to utilize Yukata:

```ruby
class Person < Yukata::Base
  attribute :first_name, String
  attribute :last_name,  String
  attribute :born_on,    DateTime
  attribute :married,    Boolean, default: -> { false }
end
```

The `#attribute` method is straight forward with its meaning. It is dynamically
creating both getter and setter methods for the object. It can be thought of as
a fancy `attr_accessor` but with a few extra features. It provides a fast way to
discover what data type can be expected for that attribute.

## Example Usage

When using Yukata, the the initializer expects a hash to be provided or a class
that behaves like a `Hash`.

```ruby
john = Person.new({
  :first_name => 'John',
  'last_name' => 'Doe',
  :born_on => '1969-01-16T00:00:00+00:00'
})
```

Yukata will take the hash and assign the values to their respective attribute
keys. If a setter method is defined, then a corresponding value can be passed as
well.

```ruby
class Foo < Yukata::Base
  attr_accessor :bar
  attribute :qux, String
  attribute :baz, String, writer: false

  def baz=(value)
    @baz = value.to_s
  end
end

foo = Foo.new({
  bar: 'woot',
  qux: 'herp',
  baz: 'derp'
})

foo.bar # => 'woot'
foo.qux # => 'herp'
foo.bas # => 'derp'
foo.attributes # => { bar: 'woot', qux: 'herp' }
```

If a `:coerce => false` is passed, then Yukata will not attempt to coerce that
attribute and leave it as is. This can be handy if a custom coercion is desired
for the specific model. Here is an example:

```ruby
class Episode < Yukata::Base
  attribute :season, Integer
  attribute :number, Integer
  attribute :name,   String, coerce: false

  # @override overides the yukata definition
  def name=(value)
    @name = '%sx%s - %s' % [@season, @number, value]
  end
end

episode = Episode.new({ season: 1, number: 1 })
episode.name = 'Foo Bar'
episode.name # => '1x1 - Foo Bar'
```

Now, remember just because there is access directly to instance variables does
not mean it is okay to abuse them. With great power comes great responsibility,
this means I am not responsible for your mistakes.

## Setting Attribute Defaults

Sometimes the objects need default values if it is not set. Defaults are lazily
loaded. They will only be set once the getter method is called.

```ruby
class Book < Yukata::Base
  attribute :name,       String
  attribute :created_at, DateTime, default: -> { DateTime.now }
end
```

## Registering Custom Coercions

This library only comes with basic coercers. I tried to make as little
assumptions about the data coming in as I could. I believe that the consumer of
the library should be the one who defines the coercions.

If the value can not be coerced, it is simply passed through and left alone.

```ruby
Yukata.coercer.register(String, Array) do |string, target|
  string.split(' ')
end
```

## Optional Readers and Writers

When declaring an attribute, both the reader and writer can be skipped. There is
a use case where this would be handy.

```ruby
class Book < Yukata::Base
  attribute :title, String, writer: false, reader: false

  def title=(value)
    @title = value.to_s
  end

  def title
    @title
  end
end
```

This is a bit contrived, but it demonstrates the following:

  1. The expected return data type for `#title` is a `String`.
  2. Custom coercer is defined.
  3. The attribute will be included when `#attributes` is called on `Book`.

If `:writer => false` is provided, there would be no need to include
`:coerce => false` since the coercion only takes place when the value is being
set on the object.

## Conclusion

I wrote this library becaues I wanted to see how [Virtus][virtus]
accomplished this task and how I could go about doing it differently. This is a
highly configurable library that can be used to put your fat models on a diet.

### References

  * [Yukata][yukata]
  * [Virtus][virtus]

[virtus]: https://github.com/solnic/virtus
[yukata]: https://github.com/warmwaffles/yukata
