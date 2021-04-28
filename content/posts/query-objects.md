---
title: Query Objects
date: 2013-04-19
categories:
  - ruby
  - refactoring
---

I'm trying to migrate my models to be dumb data bags that have some useful state
altering methods. I've found that using query objects, I was able to reduce the
complexity of some of my models and controllers.

## The Problem

My `User` model is gigantic. It's well over 600 LOC, and it's growing at a scary
rate. Testing is becoming a nightmare because of all the methods. A few methods
I have realized, I could remove completely and extract them into query objects.

```ruby
# app/models/user.rb
class User < ActiveRecord::Base
  # ...

  def self.search text
    where {
      (users.email.like "%#{text}%") |
      (users.username.like "%#{text}%") |
      (users.first_name.like "%#{text}%") |
      (users.last_name.like "%#{text}%")
    }
  end

  # ...
end
```

Now this method isn't exactly all that complicated but my `User` model is
rittled with these methods. They are just there to be used by the controller
like so:

```ruby
# app/controllers/users_controller.rb
class UsersController < AuthorizedController
  def index
    @users = User.search(params[:q]).page(params[:page])
  end
end
```

All that method does, is execute a query. It doesn't alter the state of any
model. This could be extracted out into its own class and be isolated enough
that testing becomes very simple.


## The Solution

The solution is simple, kill The Batman. First, I need a query class. When
creating query classes, keep in mind that you need to interact with
`ActiveRecord::Relation` objects. This will allow for the query objects to be
chained and used again later.

```ruby
# app/queries/user_search_query.rb
class UserSearchQuery
  # @param [ActiveRecord::Relation] relation
  def initialize relation=User.scoped
    @relation = relation
  end

  # @param [String] text
  def search text
    @relation.where {
      (users.email.like "%#{text}%") |
      (users.username.like "%#{text}%") |
      (users.first_name.like "%#{text}%") |
      (users.last_name.like "%#{text}%")
    }
  end

  # @param [String] text
  def self.search text
    new.search(text)
  end
end
```

Second I need to replace the call to `User.search` from the `UsersController`

```ruby
# app/controllers/users_controller.rb
class UsersController < AuthorizedController
  def index
    @users = UserSearchQuery.search(params[:q]).page(params[:page])
  end
end
```

Now looking at this, it is easy to say, "Well that didn't change much", but it
did. I can remove the old method from the `User` model, and reduce the
complexity a little bit by doing this.


## Chaining

Here is an example of chaining some queries together

```ruby
# app/queries/new_users_query.rb
class NewUsersQuery
  # @param [ActiveRecord::Relation] relation
  def initialize relation=User.scoped
    @relation = relation
  end

  def today date=DateTime.now
    between(date.beginning_of_day, date.end_of_day)
  end

  def last_seven_days
    date = DateTime.now.begninning_of_day
    between(date - 7.days, date.end_of_day)
  end

  def between starting, ending
    @relation.where {
      (users.created_at >= starting) &
      (users.created_at < ending)
    }
  end
end
```

Now this may sound a little dumb, but this is merely just an example.

```ruby
query = UserSearchQuery.new(NewUsersQuery.today)
query.search('someone').each do |user|
  NotificationMailer.welcome(user).deliver
end
```


## References

  * [7 Patterns to Refactor Fat ActiveRecord Models](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/)
