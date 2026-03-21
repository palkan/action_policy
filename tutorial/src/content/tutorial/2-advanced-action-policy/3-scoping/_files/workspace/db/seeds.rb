alice = User.find_or_create_by!(email_address: "alice@example.org") do |u|
  u.name = "Alice"
  u.password = "s3cr3t"
  u.password_confirmation = "s3cr3t"
  u.role = "customer"
end

bob = User.find_or_create_by!(email_address: "bob@example.org") do |u|
  u.name = "Bob"
  u.password = "s3cr3t"
  u.password_confirmation = "s3cr3t"
  u.role = "agent"
  u.level = 2
end

charlie = User.find_or_create_by!(email_address: "charlie@example.org") do |u|
  u.name = "Charlie"
  u.password = "s3cr3t"
  u.password_confirmation = "s3cr3t"
  u.role = "admin"
  u.level = 3
end

dana = User.find_or_create_by!(email_address: "dana@example.org") do |u|
  u.name = "Dana"
  u.password = "s3cr3t"
  u.password_confirmation = "s3cr3t"
  u.role = "customer"
end

eve = User.find_or_create_by!(email_address: "eve@example.org") do |u|
  u.name = "Eve"
  u.password = "s3cr3t"
  u.password_confirmation = "s3cr3t"
  u.role = "customer"
end

# Sample tickets
Ticket.find_or_create_by!(title: "Can not reset my password") do |t|
  t.description = "I tried to reset my password but never received the email. Can someone help?"
  t.status = "open"
  t.escalation_level = 1
  t.user = alice
end

t2 = Ticket.find_or_create_by!(title: "Billing discrepancy on invoice #1042") do |t|
  t.description = "I was charged twice for my last subscription renewal. Please investigate."
  t.status = "in_progress"
  t.escalation_level = 2
  t.user = alice
  t.agent = bob
end

Ticket.find_or_create_by!(title: "Feature request: dark mode") do |t|
  t.description = "It would be great to have a dark mode option for the dashboard."
  t.status = "resolved"
  t.escalation_level = 1
  t.user = alice
end

Ticket.find_or_create_by!(title: "Search is extremely slow") do |t|
  t.description = "The search feature takes over 10 seconds to return results."
  t.status = "open"
  t.escalation_level = 1
  t.user = dana
end

Ticket.find_or_create_by!(title: "Can not log in from mobile") do |t|
  t.description = "I keep getting session expired errors on my phone."
  t.status = "in_progress"
  t.escalation_level = 1
  t.user = eve
  t.agent = bob
end

# Sample comments
Comment.find_or_create_by!(ticket: t2, user: bob, body: "Looking into this now. Pulled up the payment logs.")
Comment.find_or_create_by!(ticket: t2, user: bob, body: "Confirmed duplicate charge. Refund initiated.", internal: true)
Comment.find_or_create_by!(ticket: t2, user: alice, body: "Thanks for looking into this!")
