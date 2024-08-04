class AddSlotColumnToSchedulesTable < ActiveRecord::Migration[7.1]
  def up
    add_column :schedules, :slot, :integer, null: false, default: 0

    remove_index :schedules, name: "index_schedules_on_member_id_and_date"
    add_index :schedules, [:member_id, :date, :slot], unique: true, name: "index_schedules_on_member_id_and_date_and_slot"
  end

  def down
    remove_index :schedules, name: "index_schedules_on_member_id_and_date_and_slot"
    add_index :schedules, [:member_id, :date], unique: true, name: "index_schedules_on_member_id_and_date"

    remove_column :schedules, :slot
  end
end
