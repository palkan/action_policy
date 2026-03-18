User.create!(
  name: "Alice",
  email_address: "alice@example.org",
  password: "s3cr3t",
  password_confirmation: "s3cr3t"
) unless User.where(email_address: "alice@example.org").exists?

User.create!(
  name: "Bob",
  email_address: "bob@example.org",
  password: "s3cr3t",
  password_confirmation: "s3cr3t"
) unless User.where(email_address: "bob@example.org").exists?
