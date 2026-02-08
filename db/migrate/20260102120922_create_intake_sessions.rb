class CreateIntakeSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :intake_sessions do |t|
      t.references :intake, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
