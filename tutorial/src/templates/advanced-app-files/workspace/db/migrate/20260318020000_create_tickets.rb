class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "open"
      t.integer :escalation_level, null: false, default: 1
      t.references :user, null: false, foreign_key: true
      t.references :agent, null: true, foreign_key: {to_table: :users}

      t.timestamps
    end
  end
end
