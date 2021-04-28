---
title: Ruby Mixins
date: 2015-01-17T12:00:00
categories:
  - ruby
---

Mixins are a bit of a touchy spot for me. I am in a love hate relationship when
it comes to them. In some cases, they work brilliantly and in other cases they
hide complexity.

I have a few rules that I try to follow when I am considering using mixins.

  1. Does it hide complexity / indirection?
  2. Will it benefit the code base to share code?
  3. Will it override methods or will methods need to be overriden?

Moving methods into mixins to just move them is not sufficient enough to warrant
the need for mixins. It is something that should be used to refactor once a
pattern is established. Mixins should only be used for adding abilities to
classes.

Let's take a look at an example. We need an ability to revoke tokens mixed into
three separate classes.

```ruby
module Revokable
  # Sets when the token was revoked
  # @return [void]
  def revoke
    @revoked_at = Time.now
  end

  # Check to see if the token was revoked
  # @return [TrueClass,FalseClass]
  def revoked?
    !!@revoked_at
  end
end
```

The personal token represents a token that belongs to a user and never expires,
but it can be revoked.

```ruby
class PersonalToken
  include Revokable

  attr_accessor :id, :token, :user_id
end
```

The access token represents a token that is only available for a limited time.

```ruby
class AccessToken
  include Revokable

  attr_accessor :id, :token, :user_id, :refresh_token_id

  def expire
    @expired_at = Time.now
  end

  def expired?
    !!@expired
  end
end
```

The refresh token never expires but is only used for getting another access
token.

```ruby
class RefreshToken
  include Revokable

  attr_accessor :id, :token, :user_id
end
```

We have accomplished is adding an ability to three classes without hiding a lot
of complexity. If you find that your classes have too many methods defined, that
should be a sign that it is too complex. But, do not immediately reach for
mixins just because it makes the class less cluttered. It actually hides the
mess as opposed to solving the issue.

Use mixins wisely!
