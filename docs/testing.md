# Testing

Authorization is one of the crucial parts of your application. Hence, it should be thoroughly tested (that is the place where 100% coverage makes sense).

When you use policies for authorization, it is possible to split testing into two parts:
- Test the policy class itself
- Test that **the required authorization is performed** within your authorization layer (controller, channel, etc.)
- Test that **the required scoping has been applied**.

## Testing policies

You can test policies as plain-old Ruby classes, no special tooling is required.

Consider an RSpec example:

```ruby
describe PostPolicy do
  let(:user) { build_stubbed(:user) }
  let(:post) { build_stubbed(:post) }

  let(:policy) { described_class.new(post, user: user) }

  describe "#update?" do
    subject { policy.apply(:update?) }

    it "returns false when the user is not admin nor author" do
      is_expected.to eq false
    end

    context "when the user is admin" do
      let(:user) { build_stubbed(:user, :admin) }

      it { is_expected.to eq true }
    end

    context "when the user is an author" do
      let(:post) { build_stubbed(:post, user: user) }

      it { is_expected.to eq true }
    end
  end
end
```

## Testing authorization

To test the act of authorization you have to make sure that the `authorize!` method is called with the appropriate arguments.

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

If you omit `.with(PostPolicy)` then the inferred policy for the target (`post`) would be used.

## Testing scoping

Action Policy provides a way to test that a correct scoping has been applied during the code execution.

For example, you can test that in your `#index` action the correct scoping is used:

```ruby
class UsersController < ApplicationController
  def index
    @user = authorized(User.all)
  end
end
```

**NOTE:** it's not possible to test that a scoped has been applied to a particular _target_. Thus there could be false positives.

### Minitest

Include `ActionPolicy::TestHelper` to your test class and you'll be able to use
`assert_have_authorized_scope` assertion:

```ruby
# in your test
require "action_policy/test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include ActionPolicy::TestHelper

  test "index has authorized scope" do
    sign_in users(:john)

    assert_have_authorized_scope(type: :active_record_relation, with: UserPolicy) do
      get :index
    end
  end
end
```

You can also specify `as` option.

**NOTE:** both `type` and `with` params are required.
