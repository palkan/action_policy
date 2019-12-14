# frozen_string_literal: true

require "active_record"

require "activerecord-jdbc-adapter" if defined? JRUBY_VERSION
require "activerecord-jdbcsqlite3-adapter" if defined? JRUBY_VERSION

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: true do |t|
    t.string :name
    t.string :role, default: "guest", null: false
    t.timestamps null: true
  end

  create_table :posts, force: true do |t|
    t.integer :user_id
    t.string :title
    t.boolean :draft, default: true, null: false
    t.timestamps null: true
  end
end

ActiveRecord::Base.cache_versioning = true if ActiveRecord::Base.respond_to?(:cache_versioning)

module AR
  class User < ActiveRecord::Base
    has_many :posts, foreign_key: :user_id, class_name: "AR::Post"

    def self.policy_name
      "UserPolicy"
    end

    def admin?
      role == "admin"
    end
  end

  class Post < ActiveRecord::Base
    belongs_to :user, class_name: "AR::User"

    def self.policy_name
      "PostPolicy"
    end
  end
end
