#<--rubocop/md--># GraphQL integration
#<--rubocop/md-->
#<--rubocop/md-->You can use Action Policy as an authorization library for you [GraphQL Ruby](https://graphql-ruby.org/) application via the [`action_policy-graphql` gem](https://github.com/palkan/action_policy-graphql).
#<--rubocop/md-->
#<--rubocop/md-->This integration provides the following features:
#<--rubocop/md-->- Fields & mutations authorization
#<--rubocop/md-->- List and connections scoping
#<--rubocop/md-->- **Exposing permissions/authorization rules in the API**.
#<--rubocop/md-->
#<--rubocop/md-->## Getting Started
#<--rubocop/md-->
#<--rubocop/md-->First, add `action_policy-graphql` gem to your Gemfile (see [installation instructions](https://github.com/palkan/action_policy-graphql#installation)).
#<--rubocop/md-->
#<--rubocop/md-->Then, include `ActionPolicy::GraphQL::Behaviour` to your base type (or any other type/mutation where you want to use authorization features):
#<--rubocop/md-->
#<--rubocop/md-->```ruby
# For fields authorization, lists scoping and rules exposing
class Types::BaseObject < GraphQL::Schema::Object
  include ActionPolicy::GraphQL::Behaviour
end

# For using authorization helpers in mutations
class Types::BaseMutation < GraphQL::Schema::Mutation
  include ActionPolicy::GraphQL::Behaviour
end
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->## Authorization Context
#<--rubocop/md-->
#<--rubocop/md-->By default, Action Policy use `context[:current_user]` as the `user` [authorization context](./authoriation_context.md).
#<--rubocop/md-->
#<--rubocop/md-->**NOTE:** see below for more information on what's included into `ActionPolicy::GraphQL::Behaviour`.
#<--rubocop/md-->
#<--rubocop/md-->## Authorizing Fields
#<--rubocop/md-->
#<--rubocop/md-->You can add `authorize: true` option to any field (=underlying object) to protect the access (it's equal to calling `authorize! object, to: :show?`):
#<--rubocop/md-->
#<--rubocop/md-->```ruby
# authorization could be useful for find-like methods,
# where the object is resolved from the provided params (e.g., ID)
field :home, Home, null: false, authorize: true do
  argument :id, ID, required: true
end

def home(id:)
  Home.find(id)
end

# Without `authorize: true` the code would look like this
def home(id:)
  Home.find(id).tap { |home| authorize! home, to: :show? }
end
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->You can use authorization options to customize the behaviour, e.g. `authorize: {to: :preview?, with: CustomPolicy}`.
#<--rubocop/md-->
#<--rubocop/md-->By default, if a user is not authorized to access the field, an `ActionPolicy::Unauthorized` exception is raised.
#<--rubocop/md-->
#<--rubocop/md-->If you want to return a `nil` instaed you should add `raise: false` to the options:
#<--rubocop/md-->
#<--rubocop/md-->```ruby
# NOTE: don't forget to mark your field as nullable
field :home, Home, null: true, authorize: {raise: false}
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->You can make non-raising behaviour a default by setting a configuration option:
#<--rubocop/md-->
#<--rubocop/md-->```ruby
ActionPolicy::GraphQL.authorize_raise_exception = false
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->You can also change the default `show?` rule globally:
#<--rubocop/md-->
#<--rubocop/md-->```ruby
ActionPolicy::GraphQL.default_authorize_rule = :show_graphql_field?
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->### Class-level authorization
#<--rubocop/md-->
#<--rubocop/md-->You can use Action Policy in the class-level [authorization hooks](https://graphql-ruby.org/authorization/authorization.html) (`self.authorized?`) like this:
#<--rubocop/md-->
#<--rubocop/md-->```ruby
class Types::Friendship < Types::BaseObject
  def self.authorized?(object, context)
    super &&
      object.allowed_to?(
        :show?,
        object,
        context: {user: context[:current_user]}
      )

  end
end
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->## Authorizing Mutations
#<--rubocop/md-->
#<--rubocop/md-->Mutation is just a Ruby class with a single API method. There is nothing specific in authorizing mutations: from the Action Policy point of view they are just [_behaviours_](./behaviour.md).
#<--rubocop/md-->
#<--rubocop/md-->If you want to authorize the mutation, you call `authorize!` method. For example:
#<--rubocop/md-->
#<--rubocop/md-->```ruby
class Mutations::DestroyUser < Types::BaseMutation
  argument :id, ID, required: true

  def resolve(id:)
    user = User.find(id)

    # Raise an exception if user has not enough permissions
    authorize! user, to: :destroy?
    # Or check without raising and do what you want
    #
    #     if allowed_to?(:destroy?, user)

    user.destroy!

    {deleted_id: user.id}
  end
end
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->## Handling exceptions
#<--rubocop/md-->
#<--rubocop/md-->The query would fail with `ActionPolicy::Unauthorized` exception when using `authorize: true` (in raising mode) or calling `authorize!` explicitly.
#<--rubocop/md-->
#<--rubocop/md-->That could be useful to handle this exception and send a more detailed error message to the client, for example:
#<--rubocop/md-->
#<--rubocop/md-->```ruby
# in your schema file
rescue_from(ActionPolicy::Unauthorized) do |exp|
  raise GraphQL::ExecutionError.new(
    # use result.message (backed by i18n) as an error message
    exp.result.message,
    # use GraphQL error extensions to provide more context
    extensions: {
      code: :unauthorized,
      fullMessages: exp.result.reasons.full_messages,
      details: exp.result.reasons.details
    }
  )
end
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->## Scoping Data
#<--rubocop/md-->
#<--rubocop/md-->You can add `authorized_scope: true` option to a field (list or [_connection_](https://graphql-ruby.org/relay/connections.html)) to apply the corresponding policy rules to the data:
#<--rubocop/md-->
#<--rubocop/md-->```ruby
class CityType < ::Common::Graphql::Type
  # It would automatically apply the relation scope from the EventPolicy to
  # the relation (city.events)
  field :events, EventType.connection_type,
        null: false,
        authorized_scope: true

  # you can specify the policy explicitly
  field :events, EventType.connection_type,
        null: false,
        authorized_scope: {with: CustomEventPolicy}

  # without the option you would write the following code
  def events
    authorized_scope object.events
    # or if `with` option specified
    authorized_scope object.events, with: CustomEventPolicy
  end
end
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->See the documenation on [scoping](./scoping.md).
#<--rubocop/md-->
#<--rubocop/md-->## Exposing Authorization Rules
#<--rubocop/md-->
#<--rubocop/md-->With `action_policy-graphql` gem, you can easily expose your authorization logic to the client in a standardized way.
#<--rubocop/md-->
#<--rubocop/md-->For example, if you want to "tell" the client which actions could be performed against the object you
#<--rubocop/md-->can use the `expose_authorization_rules` macro to add authorization-related fields to your type:
#<--rubocop/md-->
#<--rubocop/md-->```ruby
class ProfileType < Types::BaseType
  # Adds can_edit, can_destroy fields with
  # AuthorizationResult type.

  # NOTE: prefix "can_" is used by default, no need to specify it explicitly
  expose_authorization_rules :edit?, :destroy?, prefix: "can_"
end
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->**NOTE:** you can use [aliases](./aliases.md) here as well as defined rules.
#<--rubocop/md-->
#<--rubocop/md--> **NOTE:** This feature relies the [_failure reasons_](./reasons.md) and
#<--rubocop/md-->the [i18n integration](./i18n.md) extensions. If your policies don't include any of these,
#<--rubocop/md-->you won't be able to use it.
#<--rubocop/md-->
#<--rubocop/md-->Then the client could perform the following query:
#<--rubocop/md-->
#<--rubocop/md-->```gql
#<--rubocop/md-->{
#<--rubocop/md-->  post(id: $id) {
#<--rubocop/md-->    canEdit {
#<--rubocop/md-->      # (bool) true|false; not null
#<--rubocop/md-->      value
#<--rubocop/md-->      # top-level decline message ("Not authorized" by default); null if value is true
#<--rubocop/md-->      message
#<--rubocop/md-->      # detailed information about the decline reasons; null if value is true or you don't have "failure reasons" extension enabled
#<--rubocop/md-->      reasons {
#<--rubocop/md-->        details # JSON-encoded hash of the form { "event" => [:privacy_off?] }
#<--rubocop/md-->        fullMessages # Array of human-readable reasons
#<--rubocop/md-->      }
#<--rubocop/md-->    }
#<--rubocop/md-->
#<--rubocop/md-->    canDestroy {
#<--rubocop/md-->      # ...
#<--rubocop/md-->    }
#<--rubocop/md-->  }
#<--rubocop/md-->}
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->You can override a custom authorization field prefix (`can_`):
#<--rubocop/md-->
#<--rubocop/md-->```ruby
ActionPolicy::GraphQL.default_authorization_field_prefix = "allowed_to_"
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->## Custom Behaviour
#<--rubocop/md-->
#<--rubocop/md-->Including the default `ActionPolicy::GraphQL::Behaviour` is equal to adding the following to your base class:
#<--rubocop/md-->
#<--rubocop/md-->```ruby
class Types::BaseObject < GraphQL::Schema::Object
  # include Action Policy behaviour and its extensions
  include ActionPolicy::Behaviour
  include ActionPolicy::Behaviours::ThreadMemoized
  include ActionPolicy::Behaviours::Memoized
  include ActionPolicy::Behaviours::Namespaced

  # define authorization context
  authorize :user, through: :current_user

  # add a method helper to get the current_user from the context
  def current_user
    context[:current_user]
  end

  # extend the field class to add `authorize` and `authorized_scope` options
  field_class.prepend(ActionPolicy::GraphQL::AuthorizedField)

  # add `expose_authorization_rules` macro
  include ActionPolicy::GraphQL::Fields
end
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->Feel free to create your own behaviour by adding only the functionality you need.
