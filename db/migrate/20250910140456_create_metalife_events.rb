class CreateMetalifeEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :metalife_events do |t|
      t.references :metalife_user, foreign_key: true, index: true
      t.string :event_type, null: false
      t.string :space_id, null: false
      t.string :floor_id
      t.text :message
      t.jsonb :payload
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :metalife_events, [:metalife_user_id, :occurred_at]
    add_index :metalife_events, [:event_type, :occurred_at]
    add_index :metalife_events, :space_id
    add_index :metalife_events, :occurred_at
  end
end
