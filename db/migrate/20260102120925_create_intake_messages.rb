class CreateIntakeMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :intake_messages do |t|
      t.references :intake_session, null: false, foreign_key: true
      t.integer :role, null: false
      t.text :content, null: false

      t.timestamps
    end
  end
end
