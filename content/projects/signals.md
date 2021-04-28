---
title: Signals
date: 2017-01-01
---

[source code](https://github.com/warmwaffles/signals)

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
