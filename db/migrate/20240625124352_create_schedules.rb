class CreateSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :schedules do |t|
      t.references :member, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :status, null: false, default: 0
      t.string :memo, limit: 255

      t.timestamps
    end

    add_index :schedules, :date
    add_index :schedules, %i[member_id date], unique: true
  end
end
