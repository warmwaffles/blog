---
title: Organizing Delayed Jobs
date: 2012-12-13
categories:
  - Development
tags:
  - ruby
  - background jobs
---

I despise consuming 3rd party APIs for one reason, speed. Many of the APIs I
have to consume on a daily basis, respond slower than it would take to deliver
an email. But, their integration with our application is absolutely critical.
They are so critical infact, that if an error should happen during any point of
the commissioning, then I need to be notified and or the job needs to be
reattempted at a later date.

On many occassions, I have simply split the 3rd party API object into its own
Rails model that is persisted in the database with a `state_machine` or some
sort of identifier on it that lets the application know if it is in an erroneous
state.

Billing is a prime example of this:

```ruby
# app/models/subscription.rb
#  Table: subscriptions
#    - user_id
#    - subscription_id
class Subscription
  belongs_to :user

  def subscribe
    # subscribe to api here
    # set subscription_id = id in api
  end

  def unsubscribe
    # unsubscribe from api here
    # invoke .destroy
  end

  def update_billing_information
    # interact with api here
  end
end
```

I mentioned earlier that I would use a state machine on models that interact
with APIs. However, in this example, if the `subscription_id` is not set, then
the `Subscription` will be in an erroneous state.

I prefer to make job classes, only because they allow for me to separate my
backgrounding code, from my model code. Plus, there is the possibility that you
are sticking too much data into the delayed job queue by doing
`User.delay.send_some_email` or `@user.delay.send_some_email` is even worse. It
will turn that ruby object into a YAML formatted object and stick it into the
queue.

The following is the best way, IMO to do backgrounding with Delayed Job. Just
put a few simple values in and it keeps the queue lean.

```ruby
# app/jobs/subscribe_subscription.rb
class SubscribeSubscription
  def initialize id
    @id = id
  end

  def perform
    subscription = Subscription.find(@id)
    subscription.subscribe
  end

  def error job, exception
    puts "[ERROR] subscription=#{@id} message=#{exception.message}"
  end
end
```

I would then invoke the `Delayed::Job` queue by using an observer. Now this part
you don't have to necessarily put into an observer, but it makes for a cleaner
model. As an aside, I store my observers in `app/observers`, it just makes it a
little easier to organize my thoughts.

```ruby
# app/observers/subscription_observer.rb
class SubscriptionObserver < ActiveRecord::Observer
  def after_create subscription
    Delayed::Job.enqueue(SubscribeSubscription.new(subscription.id))
  end
end
```

We would then be able to do the following:

```ruby
# app/controllers/subscriptions_controller.rb
class SubscriptionsController < AuthorizedController
  # ...

  def create
    sub  = current_user.subscriptions.build(subscription_params)

    if sub.save
      # success
    else
      # booo failure
    end
  end

  # ...

  private

  def subscription_params
    params.require(:subscription).permit(:name, :more, :fields)
  end
end
```

We have decoupled the 3rd party interaction from the controller and put it into
a background job, where it will be handled. However, in this straw man example I
did not show a proper way to handle failure. If I was going to actually do this
with a payment system, I would definitely notify the user that something is up
and make them reattempt the sign up again.
