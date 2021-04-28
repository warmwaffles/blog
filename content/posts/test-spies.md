---
title: Test Spies
date: 2013-10-01
categories:
  - ruby
  - rspec
---

Test spies are a wonderful tool to utilize in the RSpec testing environment.
When used in moderation and with care. Test spies require that a called method
be stubbed so that it can be checked to see how it was invoked.

I have put together a really simple class to demonstrate a test spy.

```ruby
class NotifyUser
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def execute(params={})
    mailer.notify({ message: params[:message] })
  end

  def mailer
    SomeMailer.new(user)
  end
end
```

Notice in the test below that a test spy follows a pattern. There is a *mock up*
section, an *excercise* section, and a *verification* section. Each of these are
important and I always put a space in between the sections. It's much easier to
see what is happening in the test.

```ruby
describe NotifyUser do
  let(:user) { double('User') }
  let(:command) { NotifyUser.new(user) }

  describe '#execute' do
    it 'sends the notification to the user' do
      # Mock up
      mailer = double('SomeMailer', notify: true)
      command.stub(mailer: mailer)

      # Excercise
      command.execute({message: 'Hello'})

      # Verification
      expect(mailer).to have_received(:notify).with({ message: 'Hello'})
    end
  end
end
```

Mocking up outside of the `it` block should be kept to a minimum. This is
because it can get to be a little hectic trying to understand what the test is
doing. I like tests that are readable and succinct.

If the length of a test file is forcing me to start mocking outside of `it`
blocks, I like take a step back and ask myself, "Is this class really complex?"
It is important to realize when tests are getting more and more difficult to
maintain, that the code base is most likely really coupled.

## When to use them

Test spies are not meant to be used everywhere. I typically use them when a
class is communicating with an external object. I will stub the method that
wraps the object and make it return a `double`. This is so if the code base does
change, this test will fail quickly and force the developer to look at what it
failed and possibly refactor tests.

Do not apply liberally, but do apply where necessary.
