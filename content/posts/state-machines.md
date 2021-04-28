---
title: State Machines
date: 2013-07-09 12:00:00 -0600
comments: false
sharing: false
categories:
  - ruby
  - rails
---

A state machine is an interesting design pattern.

The [state_machine][state-machine] gem is a great library. It provides a nice
structure to declare states and transitions. It also provides nice callback
hooks that can be utilized to run specific actions before or after a transition
happens.

It has hooks into `ActiveRecord` and saves the model when the transition from
one state to another is successful. The gem also works just fine with plain old
ruby objects as well. Here is a simple example of a state machine.

```ruby
class Ticket < ActiveRecord::Base
  state_machine :state, :initial => :stopped do
    state :stopped
    state :started

    event :start do
      transition :stopped => :started
    end

    event :stop do
      transition :started => :stopped
    end
  end
end
```

To interact with the state machine, you can do the following:

```ruby
ticket = Ticket.create(subject: 'New issue with post', content: 'Some text')
ticket.start #=> true
ticket.state #=> 'started'
ticket.start #=> false
ticket.state #=> 'started'
ticket.stop  #=> true
ticket.state #=> 'stopped'
```

Earlier in [Dumb Data Objects][dumb-data-objects] I talked very
briefly about how to integrate a state machine into a Dumb Data Object. What
this gem brings to the table is another way back into "Callback Hell", and that
is something everyone should avoid.

The transition callbacks are there to be used sparingly. If the need arises to
apply a callback to the state machine, think about the implications this can
have on the object through out its lifetime. Will this callback make interaction
easier or will it complicate the model and make it difficult for someone else to
pick up?

One callback that is typically rife with code smell is the `after_transition`
callback. This callback will trigger an action after a transition from one state
to another has taken place. Why not just execute that method after the event was
triggered? It's very easy to do.

State machines are supposed to be simple. If transitions become complex, then
the state machine flow becomes disruptive and difficult to ascertain. The
ultimate goal is to move crazy logic out of the model and push that off into
service objects and command objects like the following:

```ruby
class StartTicket
  def initialize(ticket)
    @ticket = ticket
  end

  def execute
    if @ticket.start
      notify = NotifyTicketSubscribers.new(@ticket)
      notify.send_ticket_started_email
      true
    else
      false
    end
  end
end
```

If I were to mix in the [Signals Gem][signals]
and implement a command pattern, it would look like the following:

```ruby
class StartTicket
  include Signals::Publisher

  def initialize(ticket)
    @ticket = ticket
  end

  def execute
    if @ticket.start
      broadcast(:start_ticket_successful, @ticket)
    else
      broadcast(:start_ticket_failed, @ticket)
    end
  end
end
```

Testing `StartTicket` becomes really easy at this point.

```ruby
# Use 'rspec', >= '2.14.0.rc1' in order to
# utilize test spies
describe StartTicket do
  describe '#execute' do
    it 'should start the ticket' do
      # Mock
      ticket = double('Ticket', start: true)
      command = StartTicket.new(ticket)
      command.stub(broadcast: true)

      # Excercise
      command.execute

      # Verify
      command.should(
        have_received(:broadcast).
        with(:start_ticket_successful, ticket)
      ).once
      ticket.should have_received(:start).once
    end
  end
end
```

The `after_transition` callbacks will be pushed off onto the listeners and
`before_transition` calls will be done before the event is ever triggered in the
`StartTicket#execute` method.

```ruby
class TicketListener
  include Signals::Subscriber

  listen_for :start_ticket_successful => :send_ticket_started_email
  listen_for :stop_ticket_successful => :send_ticket_stopped_email

  def send_ticket_started_email(ticket)
    # Send out emails
  end

  def send_ticket_stopped_email(ticket)
    # Send out emails
  end
end
```

Piecing it all together, results in this simple use case.

```ruby
ticket  = Ticket.find(1)
command = StartTicket.new(ticket)
command.subscribe(TicketListener.new)
command.execute
```

Yes there is a lot of boiler-plate code, but trust me when I say the benefits
greatly out weighs the drawbacks.

For the love that is programming and refactoring, **stay away from callbacks!**

## Resources

  * [State Machine Gem][state-machine]
  * [Signals Gem][signals]

[dumb-data-objects]: /blog/2013/07/07/dumb-data-objects
[state-machine]: https://github.com/pluginaweek/state_machine
[signals]: https://github.com/warmwaffles/signals
