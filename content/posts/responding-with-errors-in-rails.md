---
title: Responding With Errors in Rails
date: 2013-10-18
categories:
  - rails
  - ruby
---

As I work on API projects I find myself having to track down status codes and
ensuring a consistent response code for any given error. Keeping these status
codes consistent throughout the application starts to become a hassle.

A solution that I stumbled upon happened to be something very simple.

```ruby
# /lib/errors/unauthorized_access_error.rb
module Errors
  class UnauthorizedAccessError
    def status
      403
    end

    def message
      'unauthorized access'
    end

    def to_hash
      {
        meta: {
          code: status,
          message: message
        }
      }
    end

    def to_json(*)
      to_hash.to_json
    end
  end
end
```

In my controller I would do the following:

```ruby
class API::V1::UsersController < API::V1::ApplicationController
  before_filter :authorize!

  def index
    render(json: account.users)
  rescue Errors::UnauthorizedAccessError => error
    render(json: error, status: error.status)
  end
end
```

Very simple, and very elegant. The status code travels with the
`UnauthorizedAccessError` class and is very well self documenting. This is a
very simple example however, the principle still remains that the errors
themselves carry the burden of what the HTTP response codes should be and what
the response should look like.

It could get a little tedious to keep rescuing from that one error every method,
fortunately Rails comes with a `rescue_from` and you can use that to blanket
your application.

```ruby
class API::V1::ApplicationController
  rescue_from Errors::UnauthorizedAccessError, with: :render_error

  def render_error(error)
    render(json: error, status: error.status)
  end
end

# Your other controller would then look like this!
class API::V1::UsersController < API::V1::ApplicationController
  before_filter :authorize!

  def index
    render(json: account.users)
  end
end
```

You could even take this a step further and make all of your error classes
decend from a common parent like `Errors::Error` and then do the following:

```ruby
class API::V1::ApplicationController
  rescue_from Errors::Error, with: :render_error

  def render_error(error)
    render(json: error, status: error.status)
  end
end
```

The possibilities are endless, but the benefits are huge. Keep things simple and
you'll enjoy the new found power.
