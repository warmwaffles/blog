---
title: Command Objects
date: 2013-07-10
categories:
  - ruby
  - oop
---

In any Unix based OS the command line reigns supreme. Commmands are predictable,
and return zero for success and non-zero for failures.

## Rules

The same principles can be applied to programming with some minor rule
alterations.

  * Class name must be in a similar format to `VerbNoun` (ex. `CreateResource`).
  * Instance must have an `#execute` method. It can accept arguments.
  * The only instance method that should be accessed is the `#execute` method.
  * The return type for `#execute` must be a `Boolean`.

## Example

A basic command object will look like the following:

```ruby
class CreateUser
  attr_reader :user

  # @param [Hash] params
  def initialize(params={})
    @user = User.new(params)
  end

  # @return [Boolean]
  def execute
    user.persisted? ? false : user.save
  end
end
```

Inside of the controller it would be applied like this:

```ruby
class RegistrationsController < ApplicationController
  # ...

  def create
    command = CreateUser.new(user_params)

    if command.execute
      sign_in(command.user)
      redirect_to welcome_path
    else
      @user = command.user
      render action: 'new'
    end
  end

  # ...
end
```

These rules are fairly simple to follow. The command object is not supposed to
be complex. It is supposed to break other complex tasks down into digestable,
easy to maintain, and an easy to test format. If the command starts to become
complex, consider extracting code into services or refactoring the command.

> if all you have is a hammer, everything looks like a nail - Abraham Maslow

Remember not everything looks like a nail, so apply this design pattern with
care and understand why others may opt for this in their application and why it
may or may not be a good fit for your application.

## Resources
  * [Tell Don't Ask - thoughtbot][tell-dont-ask]
  * [Service Objects][service-objects]
  * [Wisper: Command Objects][command-objects]

[tell-dont-ask]: http://robots.thoughtbot.com/post/27572137956/tell-dont-ask
[service-objects]: http://stevelorek.com/service-objects.html
[command-objects]: https://github.com/krisleech/wisper#serviceuse-casecommand-objects
