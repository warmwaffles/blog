---
layout: post
title: Exceptional Rails Handling
date: 2012-03-25 12:00:00 -0600
comments: false
sharing: false
categories:
  - ruby
  - exceptions
  - best practices
---

When I am writing a Rails application it starts out simple with a few
`if @something.save` lines that are pretty self explanatory. Then the
application grows and starts to become hairy. Take my contrived example with a
grain of salt as I can't show you production code that I am using.

```ruby
# app/controllers/widgets_controller.rb
class WidgetsController < ApplicationController

  #
  # Other methods go here
  #

  def something
    # Maybe we handle the update in a special way
    widget = Widget.find(params[:id])
    widget.some_method(params[:widget])

    # for the sake of simplicity let's change the owner
    foobar = widget.foobar
    foobar.owner = current_user

    respond_to do |format|
      if widget.save
        if foobar.save
          format.html { redirect_to widgets_path, :notice => 'Huzzah!' }
        else
          widget.some_special_rollback
          format.html { redirect_to widgets_path, :notice => "You're a moron" }
        end
      else
        format.html { redirect_to widgets_path, :notice => "Not even close"}
      end
    end
  end

end
```

What did we learn here? *Terribly contrived examples can prove anything*, No!
Though I liked how easy it was to come up with it but that is not why I wrote
the code above. I have seen applications get to that point and when I see it now
I start to shake my fist violently at the computer and wonder just what in the
world were they thinking.

After watching [Avdi Grimm][exceptional-ruby] give his excellent opinion on how
you can leverage exception handling in Ruby. I really suggest you go and check
it out at the end of this post.

Ruby offers a nice way to handle exceptions with the `begin` and `rescue` blocks
but I really don't like how `begin` can start to clutter your code up. As Grimm
has stated, *"It can be considered code smell"*, and as such should be avoided
as much as possible

The other feature that Ruby offers in regards to exception handling is that you
can define the `rescue` part at the bottom of the method. This can be extremely
advantageous when trying to organize your code. Let me demonstrate a simple
example that we see all the time from the rails generator

```ruby
# app/controllers/widgets_controller.rb
class WidgetsController < ApplicationController

  def update
    @widget = Widget.find(params[:id])
    @widget.update_attributes(params[:widget])
    @widget.save! # Throw exception if save failed

    respond_to do |format|
      format.html { redirect_to widgets_path, :notice => "It worked" }
    end
  rescue
    # Oh no, the save failed...handle all rollback issues here
    respond_to do |format|
      format.html { render :action => :new }
    end
  end
end
```

Again the example above is really dead simple but it does demonstrate the point
that you can keep your error handling code separated from your non-error code.
Now I have found times where I created two models and a third failed to be
created and I needed to rollback the changes and set a few of parent's
attributes. This is a case where the `transaction` block can be used.


```ruby
# app/controllers/invite_controller.rb
def confirm
  @user = User.find_by_token(param[:token])
  if @user
    Widget.transaction do
      wg = WidgetGroup.create!(:name => "#{@user.name} First Group")
      Widget.create!(:name => "My first widget", widget_group_id => wg.id)
      Widget.create!(:name => "this is a special widget", widget_group_id => wg.id, :special => true)
    end
    redirect_to widget_group_path(wg), :notice => 'Awesome'
  else
    redirect_to root_url, :notice => "This is a terrible app"
  end
end
```

Transactions are handy and can save you a big head ache. In Computer Science
we were always told to keep our memory leaks to a minimum and close all unused
file descriptors and other various clean up tasks which would lead me to have
special cases where I would have to tear down each object in reverse order
from where the error happened. A massive pain if the error happened 4 levels
deep.

Where as with transactions, would just rollback the changes and I would be a
happy puppy.

Below is *Avdi Grimm*'s presentation on exeption handling in Ruby and what can
be done to clean up code and is an all around way to make yourself more educated
on Ruby. Take a look.

## Resources

  * [Exceptional Ruby][exceptional-ruby]
[exceptional-ruby]: http://blip.tv/avdi-grimm/exceptional-ruby-4778405
