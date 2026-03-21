class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.text :body, null: false
      t.references :ticket, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :internal, null: false, default: false

      t.timestamps
    end
  end
end
