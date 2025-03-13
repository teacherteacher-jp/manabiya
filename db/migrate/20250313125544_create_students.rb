class CreateStudents < ActiveRecord::Migration[8.0]
  def change
    create_table :students do |t|
      t.string :name, limit: 20, null: false
      t.integer :grade, null: false
      t.integer :parent_member_id

      t.timestamps
    end

    add_foreign_key :students, :members, column: :parent_member_id
  end
end
