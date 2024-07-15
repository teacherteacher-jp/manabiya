class CreateAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :assignments do |t|
      t.references :schedule, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
