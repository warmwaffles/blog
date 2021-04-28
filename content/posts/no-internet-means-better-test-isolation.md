---
title: No Internet Means Better Test Isolation
date: 2013-02-01
categories:
  - testing
  - ruby
  - rspec
  - rails
---

One day I found myself riding in a car with my family and it was a long road
trip, with little to no internet and realized that my tests required internet
connectivity. I was also heavily dependent upon code examples that I could find.

I've been absolutely horrible with testing my code. I would write code, test it
out in the ruby console and then push it live. It felt like I was moving fast. I
was being agile. **Wrong**! Testing is _necessary_ in order to succeed. Often I
would push code and do the good ole' cowboy code em' up. This is a **horrible**
idea, **don't do that**.

## Stubs And Mocks

I've seen arguments for and against the use of stubs and mocks. I like mocks and
stubs. I do think they are useful, and they have their place. Many people find
themselves over stubbing and over mocking. This can lead to brittle tests.

> I suppose it is tempting, if the only tool you have is a hammer, to treat
> everything as if it were a nail. **Abraham H. Maslow**

Corey Haines has a good presentation called [Yay Mocks!][yay-mocks]. Definitely
worth the time to watch.

Using stubs and mocks in a restrained fashion will result in maximum payoff. I
attempted to stub and mock everything in a controller unit test. This turned out
to be a _hellish_ nightmare to maintain. I did discover some cool logical
control flow that I could utilize. I could force [CanCan][cancan]
to raise exceptions and cause some fun errors in the controller.

```ruby
# spec/controllers/threads_controller.rb
describe ThreadsController do

  describe '#create' do
    context 'when a user is signed in' do
      before { sign_in user }
      context 'and is authorized' do
        before { controller.stub(:authorize!).and_return(true) }
        context 'and the thread is created' do
          before do
            post :create, thread: {title: 'Some Title'}
          end
          it { should respond_with 302 }
          it { should set_the_flash[:success] }
          it 'should create the thread' do
            expect(Thread.count).to eq(1)
          end
        end

        context 'and the thread is not created' do
          before do
            Thread.any_instance.stub(:valid?).and_return(false)
            post :create, thread: {title: 'Some Title'}
          end
          it { should respond_with 200 }
          it { should set_the_flash[:error] }
          it 'should not create a thread' do
            expect(Thread.count).to eq(0)
          end
        end
      end

      context 'and is not authorized' do
        before do
          controller.stub(:authorize!).and_raise(CanCan::AccessDenied)
          post :create, thread: {title: 'Some Title'}
        end
        it { should respond_with 403 }
        it { should set_the_flash[:error] }
        it 'should not create a thread' do
          expect(Thread.count).to eq(0)
        end
      end
    end

    context 'when a user is not signed in' do
      before { post :create, thread: {title: 'Some Title'} }
      it { should respond_with 403 }
    end
  end

end
```

Testing permissions should not apply to controller tests. This ia a boundary and
should be stubbed. You can unit test your permissions in another set of tests,
but they **do not** belong in the controller test.

## Boundaries

I strongly urge you to watch [Boundaries][boundaries] by Gary Bernhardt.
Understanding where an object's boundaries lie, is key for test isolation. Ruby
has a nice open class principle that allows for stubing and mocking. Earlier I
pointed out that in a controller permissions were considered a boundary.

## No Internet

Now for the fun story. I had no internet on my laptop while we traveled down the
highway. I was writing code and then realized I should run my tests real quick
to ensure I didn't cause a massive problem. What I found out to my surprise is
that more than half of our test suite failed, due to the need to talk to a 3rd
party API. _Ooops_.

All I had was my phone and even then all I had was spotty coverage. I remembered
seeing the two videos mentioned above, and thought to myself, "This is similar
to what TDD is right?" I was right, as I went through and looked at why the
tests were failing, I noticed that they were failing in places that were
difficult to test. On top of the areas difficult to test, it was often over
stepping boundaries.

I used my phone to look up [RSpec Mocks][rspec-mocks-docs] and tried out a few
examples to make sure I understood what was going on.

```ruby
foo = double('User')
foo.stub(:update_attributes).and_return(true)

it 'should return true' do
  expect(foo.update_attributes({:garbage => 'in'})).to eq(true)
end
```

## Revelation

And when the test greened up, a sudden grin appeared on my face. I realized that
I could do anything. I have never once been happy about testing in Java or PHP
and I couldn't help but be really excited when I started seeing some tests come
up green.

I started to stub and mock places where I was making calls to an API. Many of
these tests, I simulated errors that could be encountered while interacting with
the API.

I realized that there were parts of our application that were extremely
difficult to isolate. This was indicative of "_code smell_". I wrote some tests
on how I wanted the peices to interact, then made the peices interact to make
the tests green.

Being able to simulate errors from the API was a _HUGE_ help. It allowed me to
see potential errors and handle them appropriately rather than show a big ole'
500 error page to our customer.

## Resources

Here is a list of resources that I utilize all the time. In fact, they are
bookmarked and I often visit them.

  * [Boundaries][boundaries]
  * [Yay Mocks!][yay-mocks]
  * [RSpec Mock Documentation][rspec-mocks-docs]
  * [RSpec Mocks Git Repo][rspec-mocks]
  * [Better Specs][better-specs]

[yay-mocks]: http://www.youtube.com/watch?v=t430e6M5YAo
[boundaries]: http://www.youtube.com/watch?v=yTkzNHF6rMs
[cancan]: https://github.com/ryanb/cancan
[rspec-mocks-docs]: https://www.relishapp.com/rspec/rspec-mocks/docs
[rspec-mocks]: https://github.com/rspec/rspec-mocks
[better-specs]: http://betterspecs.org/
