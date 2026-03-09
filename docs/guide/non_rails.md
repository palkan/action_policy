# Using with Ruby applications

Action Policy is designed to be independent of any framework and does not have specific dependencies on Ruby on Rails.

You can [write your policies](writing_policies.md) for non-Rails applications the same way as you would do for Rails applications.

In order to have `authorize!` / `allowed_to?` / `authorized` methods, you will have to include [`ActionPolicy::Behaviour`](./behaviour.md) into your class (where you want to perform authorization):

```ruby
class PostUpdateAction
  include ActionPolicy::Behaviour

  # provide authorization subject (performer)
  authorize :user

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def call(post, params)
    authorize! post, to: :update?

    post.update!(params)
  end
end
```
