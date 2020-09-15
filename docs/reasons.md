# Failure Reasons

When you have complex policy rules, it could be helpful to have an ability to define an exact reason for why a specific authorization was rejected.

It is especially helpful when you compose policies (i.e., use one policy within another) or want
to expose permissions to client applications (see [GraphQL](./graphql.md)).

Action Policy allows you to track failed `allowed_to?` checks in your rules.

Consider an example:

```ruby
class ApplicantPolicy < ApplicationPolicy
  def show?
    user.has_permission?(:view_applicants) &&
      allowed_to?(:show?, object.stage)
  end
end
```

When `ApplicantPolicy#show?` check fails, the exception has the `result` object, which in its turn contains additional information about the failure (`reasons`):

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActionPolicy::Unauthorized do |ex|
    p ex.result.reasons.details #=> { stage: [:show?] }

    # or with i18n support
    p ex.result.reasons.full_messages #=> ["You do not have access to the stage"]
  end
end
```

The reason key is the corresponding policy [identifier](writing_policies.md#identifiers).

You can also wrap _local_ rules into `allowed_to?` to populate reasons:

```ruby
class ApplicantPolicy < ApplicationPolicy
  def show?
    allowed_to?(:view_applicants?) &&
      allowed_to?(:show?, object.stage)
  end

  def view_applicants?
    user.has_permission?(:view_applicants)
  end
end

# then the reasons object could be
p ex.result.reasons.details #=> { applicant: [:view_applicants?] }

# or
p ex.result.reasons.details #=> { stage: [:show?] }
```

Reason could also be specified for `deny!` calls:

```ruby
class TeamPolicy < ApplicationPolicy
  def show?
    deny!(:no_user) if user.anonymous?

    user.has_permission?(:view_teams)
  end
end

p ex.result.reasons.details #=> { applicant: [:no_user] }
```

## Detailed Reasons

You can provide additional details to your failure reasons by using a `details: { ... }` option:

```ruby
class ApplicantPolicy < ApplicationPolicy
  def show?
    allowed_to?(:show?, object.stage)
  end
end

class StagePolicy < ApplicationPolicy
  def show?
    # Add stage title to the failure reason (if any)
    # (could be used by client to show more descriptive message)
    details[:title] = record.title

    # then perform the checks
    user.stages.where(id: record.id).exists?
  end
end

# when accessing the reasons
p ex.result.reasons.details #=> { stage: [{show?: {title: "Onboarding"}] }
```

**NOTE**: when using detailed reasons, the `details` array contains as the last element
a hash with ALL details reasons for the policy (in a form of `<rule> => <details>`).

The additional details are especially helpful when combined with localization, 'cause you can you them as interpolation data source for your translations. For example, for the above policy:

```yml
en:
  action_policy:
    policy:
      stage:
        show?: "The %{title} stage is not accessible"
```

And then when you call `full_messages`:

```ruby
p ex.result.reasons.full_messages #=> The Onboarding stage is not accessible
```

### `result.all_details`

Sometimes details could be useful not only to provide more context to the user, but to handle failures differently.

In this cases, digging through the `ex.result.reasons.details` could be cumbersome (see [this PR](https://github.com/palkan/action_policy/pull/130) for discussion). We provide a helper method, `result.all_details`, which could be used to get all details merged into a single Hash:

```ruby
rescue_from ActionPolicy::Unauthorized do |ex|
  if ex.result.all_details[:not_found]
    head :not_found
  else
    head :unauthorized
  end
end
```

----

**P.S. What is the point of failure reasons?**

Failure reasons helps you to write _actionable_ error messages, i.e. to provide a user with helpful feedback.

For example, in the above scenario, when the reason is `ApplicantPolicy#view_applicants?`, you could show the following message:

```
You don't have enough permissions to view applicants.
Please, ask your manager to update your role.
```

And when the reason is `StagePolicy#show?`:

```
You don't have access to the stage XYZ.
Please, ask your manager to grant access to this stage.
```

Much more useful than just showing "You are not authorized to perform this action," isn't it?
