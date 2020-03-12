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

### RSpec DSL

We also provide a simple RSpec DSL which aims to reduce the boilerplate when writing
policies specs.

Example:

```ruby
# Add this to your spec_helper.rb / rails_helper.rb
require "action_policy/rspec/dsl"

describe PostPolicy do
  let(:user) { build_stubbed :user }
  # `record` must be defined – it is the authorization target
  let(:record) { build_stubbed :post, draft: false }

  # `context` is the authorization context
  let(:context) { {user: user} }

  # `describe_rule` is a combination of
  # `describe` and `subject { ... }` (returns the result of
  # applying the rule to the record)
  describe_rule :show? do
    # `succeed` is `context` + `specify`, which checks
    # that the result of application is successful
    succeed "when post is published"

    # `succeed` is `context` + `specify`, which checks
    # that the result of application wasn't successful
    failed "when post is draft" do
      before { post.draft = false }

      succeed "when user is a manager" do
        before { user.role = "manager" }
      end
    end
  end
end
```

If test failed the exception message includes the result and [failure reasons](reasons) (if any):

```
1) PostPolicy#show? when post is draft
Failure/Error:  ...

Expected to fail but succeed:
<PostPolicy#show?: true (reasons: ...)>
```

If you have [debugging utils](debugging) installed the message also includes the _annotated_
source code of the policy rule:

```
1) UserPolicy#manage? when post is draft
Failure/Error:  ...

Expected to fail but succeed:
<PostPolicy#show?: true (reasons: ...)>
↳ user.admin? #=> true
OR
!record.draft? #=> false
```

**NOTE:** DSL for focusing or skipping examples and groups is also available (e.g. `xdescribe_rule`, `fsucceed`, etc.).

**NOTE:** the DSL is included only to example with the tag `type: :policy` or in the `spec/policies` folder. If you want to add this DSL to other examples, add `include ActionPolicy::RSpec::PolicyExampleGroup`.

### Testing scopes

#### Active Record relation example

There is no single rule on how to test scopes, 'cause it dependes on the _nature_ of the scope.

Here's an example of RSpec tests for Active Record scoping rules:

```ruby
describe PostPolicy do
  describe "relation scope" do
    let(:user) { build_stubbed :user }
    let(:context) { {user: user} }

    # Feel free to replace with `before_all` from `test-prof`:
    # https://test-prof.evilmartians.io/#/before_all
    before do
      create(:post, name: "A")
      create(:post, name: "B", draft: true)
    end

    let(:target) do
      # We want to make sure that only the records created
      # for this test are affected, and they have a deterministic order
      Post.where(name: %w[A B]).order(name: :asc)
    end

    subject { policy.apply_scope(target, type: :active_record_relation).pluck(:name) }

    context "as user" do
      it { is_expected.to eq(%w[A]) }
    end

    context "as manager" do
      before { user.update!(role: :manager) }

      it { is_expected.to eq(%w[A B]) }
    end

    context "as banned user" do
      before { user.update!(banned: true) }

      it { is_expected.to be_empty }
    end
  end
end
```

#### Action Controller params example

Here's an example of RSpec tests for Action Controller parameters scoping rules:

```ruby
describe PostPolicy do
  describe "params scope" do
    let(:user) { build_stubbed :user }
    let(:context) { {user: user} }

    let(:params) { {name: "a", password: "b"} }
    let(:target) { ActionController::Parameters.new(params) }

    # it's easier to asses the hash representation, not the AC::Params object
    subject { policy.apply_scope(target, type: :action_controller_params).to_h }

    context "as user" do
      it { is_expected.to eq({name: "a"}) }
    end

    context "as manager" do
      before { user.update!(role: :manager) }

      it { is_expected.to eq({name: "a", password: "b"}) }
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

RSpec composed matchers are available as target:

```ruby
expect { subject }.to be_authorized_to(:show?, an_instance_of(Post))
```

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

You can also specify `as` and `scope_options` options.

**NOTE:** both `type` and `with` params are required.

It's not possible to test that a scoped has been applied to a particular _target_ but we provide
a way to perform additional assertions against the matching target (if the assertion didn't fail):

```ruby
test "index has authorized scope" do
  sign_in users(:john)

  assert_have_authorized_scope(type: :active_record_relation, with: UserPolicy) do
    get :index
  end.with_target do |target|
    # target is a object passed to `authorized` call
    assert_equal User.all, target
  end
end
```

### RSpec

Add the following to your `rails_helper.rb` (or `spec_helper.rb`):

```ruby
require "action_policy/rspec"
```

Now you can use `have_authorized_scope` matcher:

```ruby
describe UsersController do
  subject { get :index }

  it "has authorized scope" do
    expect { subject }.to have_authorized_scope(:active_record_relation)
      .with(PostPolicy)
  end
end
```

You can also add `.as(:named_scope)` and `with_scope_options(options_hash)` options.

RSpec composed matchers are available as scope options:

```ruby
expect { subject }.to have_authorized_scope(:scope)
  .with_scope_options(matching(with_deleted: a_falsey_value))
```

You can use the `with_target` modifier to run additional expectations against the matching target (if the matcher didn't fail):

```ruby
expect { subject }.to have_authorized_scope(:scope)
  .with_scope_options(matching(with_deleted: a_falsey_value))
  .with_target { |target|
    expect(target).to eq(User.all)
  }
```


## Testing views

When you test views that call policies methods as `allowed_to?`, your may have `Missing policy authorization context: user` error.
You may need to stub `current_user` to resolve the issue.

Consider an RSpec example:

```ruby
describe "users/index.html.slim" do
  let(:user) { build_stubbed :user }
  let(:users) { create_list(:user, 2) }

  before do
    allow(controller).to receive(:current_user).and_return(user)

    assign :users, users
    render
  end

  describe "displays user#index correctly" do
    it { expect(rendered).to have_link(users.first.email, href: edit_user_path(users.first)) }
  end
end
```
