# Testing

Authorization is one of the crucial parts of your application, hence it should be thoroughly tested (that's the place where 100% coverage makes sense).

When you use policies for authorization, it is possible to split testing into two parts:
- Test that **the required authorization is performed** within your authorization layer (controller, channel, etc.)
- Test policy class itself.

## Testing authorization

In order to test the act of authorization you have to make sure that the `authorize!` method is called with the appropriate arguments.

Action Policy provides tools for such kind of testing for Minitest and RSpec.

### Minitest

Include `ActionPolicy::TestHelper` to your test class and you'll be able to use
`assert_authorized_to` assertion:

```ruby
# in your controller
class PostsController < ApplicationController
  def update
    @post = Post.find(params[:id])
    authorize! @post
    if @post.update(post_params)
      redirect_to @post
    else
      render :edit
    end
  end
end

# in your test
require "action_policy/test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  include ActionPolicy::TestHelper

  test "update is authorized" do
    sign_in users(:john)

    post = posts(:example)

    assert_authorized_to(:update?, post, with: PostPolicy) do
      patch :update, id: post.id, name: "Bob"
    end
  end
end
```

You can omit the policy (then it would be inferred from the target):

```ruby
assert_authorized_to(:update?, post) do
  patch :update, id: post.id, name: "Bob"
end
```

### RSpec

Add the following to your `rails_helper.rb` (or `spec_helper.rb`):

```ruby
require "action_policy/rspec"
```

Now you can use `be_authorized_to` matcher:

```ruby
describe PostsController do
  subject { patch :update, id: post.id, params: params }

  it "is authorized" do
    expect { subject }.to be_authorized_to(:update?, post)
      .with(PostPolicy)
  end
end
```

If you omit `.with(PostPolicy)` then the inferred policy for target (`post`) would be used.

## Testing policies

You can test policies as plain-old Ruby classes, not special tooling is required.

Consider an RSpec example:

```ruby
describe PostPolicy do
  let(:user) { build_stubbed(:user) }
  let(:post) { build_stubbed(:post) }

  let(:policy) { described_class.new(post, user: user) }

  describe "#update?" do
    subject { policy.update? }

    it "returns false when user is not admin nor author" do
      is_expected.to eq false
    end

    context "when user is admin" do
      let(:user) { build_stubbed(:user, :admin) }

      it { is_expected.to eq true }
    end

    context "when user is author" do
      let(:post) { build_stubbed(:post, user: user) }

      it { is_expected.to eq true }
    end
  end
end
```
