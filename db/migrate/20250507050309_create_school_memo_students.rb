class CreateSchoolMemoStudents < ActiveRecord::Migration[8.0]
  def change
    create_table :school_memo_students do |t|
      t.references :school_memo, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true

      t.timestamps
    end
  end
end
