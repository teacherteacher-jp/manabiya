class CreateGuardianships < ActiveRecord::Migration[8.1]
  def change
    create_table :guardianships do |t|
      t.references :student, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true

      t.timestamps
    end

    add_index :guardianships, [:student_id, :member_id], unique: true
  end
end
