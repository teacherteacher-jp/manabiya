class DropStudentMemos < ActiveRecord::Migration[8.0]
  def up
    drop_table :student_memos
  end

  def down
    create_table :student_memos do |t|
      t.references :student, null: false, foreign_key: true
      t.text :content, null: false, limit: 1000
      t.integer :category, null: false
      t.references :member, null: false, foreign_key: true

      t.timestamps
    end
  end
end
