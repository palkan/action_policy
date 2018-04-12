# Failure Reasons

When you have complex policy rules it could be helpful to have an ability to distinguish between the reasons why authorization was rejected.

It's escepially helpful when you compose policies (i.e. use one policy within another).

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

When `ApplicantPolicy#show?` check fails the exception has the `reasons` object, which contains additional information about the failure:

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActionPolicy::Unauthorized do |ex|
    p ex.reasons.messages #=> { stage: [:show?] }
  end
end
```

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
p ex.reasons.messages #=> { applicant: [:view_applicants?] }

# or
p ex.reasons.messages #=> { stage: [:show?] }
```

**What the point of failure reasons?**

First, you can provide a user with a more specific feedback. For example, in the above scenariio when the reason is `ApplicantPolicy#view_applicants?` you can show the following message:

```
You don't have enough permissions to view applicants.
Please, ask your manager to update your role.
```

And when the reason is `StagePolicy#show?`:

```
You don't have access to the stage XYZ.
Please, ask you manager to grant access to this stage.
```

It's much more useful than just showing "You are not authorized to perform this action", isn't it?
