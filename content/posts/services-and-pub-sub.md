---
title: Services and Pub Sub
date: 2013-07-03
categories:
  - Development
tags:
  - ruby
---

The Publish-Subscribe pattern is a great way to make code modular and decoupled
from the rest of the architecture. It also has a nice side-effect of making
testing easier and classes smaller.

In a pub-sub pattern, publishers don't know anything about its subscribers and
subscribers don't know anything about who is publishing to it. Subscribers are
simply listening for specific messages and handling them accordingly and
publishers are simply broadcasting messages.

Subscribers are meant to be reused with other publishers. Though often some
subscribers will only be used in one place. The value add with this approach is
that the subscriber can be removed at anytime and readded. If one were to
implement a [feature flipper][feature-flipper], dynamically adding subscribers
can be a big win.

Let's take a dive into the [Signals][signals] gem.

At a basic level a publisher can be considered a service object and any calls to
and external service can be a subscriber. Subscribers need a way to listen for
specific events and fire off the appropriate actions.

```ruby
class ActivityListener
  include Signals::Subscriber

  listen_for :failed_login => :log_failed_attempt

  def log_failed_attempt(user)
    # ... some security audit stuff ...
  end
end
```

The `ActivityListener` is now isolated away from what other subscribers are
doing. This makes testing really simple. A mocked user could be passed in and
test spies could be used to ensure that the proper methods were invoked.

Sometimes there are events that will take place that need to have multiple
actions taken. For example, when a user creates a subscription the application
will probably need to send a confirmation email along with talking to a payment
gateway while logging the request to some security tracker. This is a strawman
example, but it is something that can happen.

```ruby
class ActivityListener
  include Signals::Subscriber

  listen_for [:logged_in, :logged_out] => :log_activity

  def log_activity(user)
    # ... something ...
  end
end
```

## Example

This is something similar to how I use [Signals][signals] in production. This
does assume you are using Delayed Jobs, however if you are using a different
background job tool, I'm sure the conversion is easy enough.

```ruby
# app/services/create_user.rb
class CreateUser
  include Signals::Publisher

  def initialize(params={})
    @user = User.new(params)
  end

  def execute
    if @user.save
      broadcast(:create_user_successful, @user)
    else
      broadcast(:create_user_failed, @user)
    end
  end
end
```

```ruby
# app/jobs/welcome_email_job.rb
class WelcomeEmailJob
  def initialize(id)
    @id = id
  end

  def perform
    user = User.find(@id)
    EmailListener.new.user_created(user)
  end
end
```

```ruby
# app/listeners/email_listener.rb
class EmailListener
  include Signals::Subscriber

  listen_for :create_user_successful => :enqueue_user_created

  def enqueue_user_created(user)
    Delayed::Job.enqueue(WelcomeEmailJob.new(user.id))
  end

  def user_created(user)
    WelcomeMailer.welcome_email(user).deliver
  end
end
```

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  # ...
  def create
    service = CreateUser.new(user_params)
    service.subscribe(EmailListener.new)
    service.on(:create_user_successful) do |user|
      redirect_to root_url
    end
    service.on(:create_user_failed) do |user|
      @user = user
      render action: 'new'
    end
    service.execute
  end
  # ...
end
```

## Resources

These are some resources I found extremely helpful as I wrote the library to
further my understanding of the publish-subscriber pattern.

  * [Wisper Gem][wisper]
  * [Using Wisper to Decompose Applications][wisper-decompose]
  * [Publish-Subscribe Pattern][pub-sub]
  * [Observer Pattern][observer]

[wisper]: https://github.com/krisleech/wisper
[wisper-decompose]: http://rubysource.com/using-wisper-to-decompose-applications/
[pub-sub]: http://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern
[observer]: http://en.wikipedia.org/wiki/Observer_pattern
[feature-flipper]: https://github.com/pda/flip
[signals]: https://github.com/warmwaffles/signals
