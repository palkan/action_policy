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
    p ex.reasons.messages  #=> { stage: [:show?] }
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
p ex.reasons.messages  #=> { applicant: [:view_applicants?] }

# or
p ex.reasons.messages  #=> { stage: [:show?] }
```
