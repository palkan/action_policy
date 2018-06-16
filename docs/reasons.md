# Failure Reasons

When you have complex policy rules, it could be helpful to have an ability to define an exact reason for why a specific authorization was rejected.

It is especially helpful when you compose policies (i.e., use one policy within another).

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

**NOTE:** `full_messages` support hasn't been released yet. See [the issue](https://github.com/palkan/action_policy/issues/15).

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



**What is the point of failure reasons?**

First, you can provide a user with helpful feedback. For example, in the above scenario, when the reason is `ApplicantPolicy#view_applicants?`, you could show the following message:

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
