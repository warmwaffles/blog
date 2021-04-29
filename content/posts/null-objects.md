---
title: Null Objects
date: 2013-06-24
categories:
  - Development
tags:
  - ruby
  - rails
---

Rails is a wonderful library. It's a framework that is opinionated and requires
some footwork on the developers part. One such issue is returning `nil` when the
return type is an object. Returning nill doesn't provide the view enough
information about what actions to take and leads to complex whack-a-mole
scenarios.

The solution to this problem is to introduce a `NullObject` into the
application. There are null object libraries already available, but they are so
dead simple to write that it's not necessary to use one. For example, it would
be trivial to declare this basic `NullObject`.

```ruby
class NullObject
  def to_s
    ""
  end

  def method_missing(*args, &block)
    self
  end
end

object = NullObject.new
object.this.doesnt.exist #=> <NullObject>
```

This is extremely handy when query objects are used.

## Maybes

Maybes are really handy. It's similar to the `#try` method that is in Rails.

```ruby
user.try(:non_existent_method, NullObject.new) #=> <NullObject>
```

Instead, when the foreign key is not set, the method will return the
`NullObject`.

```ruby
class User < ActiveRecord::Base
  belongs_to :subscription

  def subscription
    self.subscription_id? ? super : NullObject.new
  end
end
```

This allows us to use the null object while still providing the original
`ActiveRecord` functionality.

```ruby
user = User.find(1)
user.subscription #=> <NullObject>
user.subscription.product #=> <NullObject>
user.subscription_id = 1
user.subscription #=> <Subscription>
user.subscription.product #=> <Product>
```

## Falsiness

An issue that will be encountered is testing the falsiness of a `NullObject`.
The following will not work:

```ruby
obj = NullObject.new

unless obj
  # Never executes
  puts "I'm true"
end
```

A work around that should be used is defining `nil?` on an instance of
`NullObject`.

```ruby
class NullObject
  def to_s; ""; end
  def nil?; true; end

  def method_missing(*args, &block)
    self
  end
end

obj = NullObject.new

if obj.nil?
  puts "I'm true"
end
```

This makes the code readable at a glance. When `if some_val` is used then it can
be confusing at first and one must recall the old *Perl* style of programming.
In *Perl* `nil` and `null` were equivalent to `FALSE`.

The final `NullObject` that I ended up using looks like the following:

```ruby
# app/models/null_object.rb
class NullObject
  def initialize(*methods, &block); end
  def to_s; ""; end
  def to_str; ""; end
  def to_i; 0; end
  def to_f; 0.0; end
  def to_c; 0.to_c; end
  def to_r; 0.to_r; end
  def to_a; []; end
  def to_ary; []; end
  def to_h; {}; end
  def nil?; true; end
  def present?; false; end
  def empty?; true; end
  def !; true; end
  def blank?; true; end

  # @return [NullObject]
  def tap
    yield(self)
    self
  end

  # @return [NullObject]
  def method_missing(*args, &block)
    self
  end
end
```

## Custom Null Objects

This goes hand to hand with the "Maybes" section of this article. When trying to
clean up view code conditionals, this is a great opportunity to use a NullObject
specific to the model expected.

```ruby
class NullSubscription < NullObject
  def product
    NullProduct.new
  end

  def active?
    false
  end
end
```

```haml app/views/users/index.html.haml
- @users.each do |user|
  %tr
    %td= user.email
    %td= user.subscription.active? ? 'Subscribed' : 'Not Subscribed'
```

The benefit of returning a null object instead of `nil` is that crazy `if`
checks wont be necessary in view code or model code. The ultimate goal of a
NullObject is to get it to behave like the object it is trying to imitate. This
adds predictability to the application and makes testing much easier.

## Resources

  * [Null Objects and Falsiness](http://devblog.avdi.org/2011/05/30/null-objects-and-falsiness/)
  * [Naught Gem](https://github.com/avdi/naught)
  * [Null Gem](https://github.com/katmagic/null)
