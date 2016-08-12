---
layout: page
title: Projects
date: 2015-03-14 12:00:00
comments: false
---

This is a list of all of the projects that I am involved in.

# [Signals](https://github.com/warmwaffles/signals)

A light-weight pub-sub ruby library that allows for event triggered blocks to be
used.

```ruby
class UsersController < ApplicationController
  def create
    command = CreateUser.new
    command.on(:success) do |user|
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t('user.create.success')
          @user = user
          redirect_to(user_path(user.id))
        end
      end
    end
    command.on(:failed) do |user|
      respond_to do |format|
        format.html do
          flash[:alert] = I18n.t('user.create.failed')
          @user = user
          render(action: 'new', status: 400)
        end
      end
    end
    command.execute(params)
  end
end
```

# [Skeleton](https://github.com/warmwaffles/skeleton)

Allows you to define swagger compatible documentation within ruby using a nice
DSL.

# [Yukata](https://github.com/warmwaffles/yukata)

# [Wellness](https://github.com/warmwaffles/wellness)

# [Sublime Text Settings](https://github.com/warmwaffles/sublime-settings)
