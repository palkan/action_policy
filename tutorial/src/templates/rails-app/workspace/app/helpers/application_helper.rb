module ApplicationHelper
  def status_badge_class(status)
    case status
    when "open" then "primary"
    when "in_progress" then "warning"
    when "resolved" then "success"
    when "closed" then "danger"
    else ""
    end
  end
end
