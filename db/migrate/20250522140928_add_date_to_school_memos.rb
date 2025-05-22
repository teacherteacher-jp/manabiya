class AddDateToSchoolMemos < ActiveRecord::Migration[8.0]
  def up
    add_column :school_memos, :date, :date

    execute <<-SQL
      UPDATE school_memos
      SET date = DATE(created_at)
    SQL

    change_column_null :school_memos, :date, false
  end

  def down
    remove_column :school_memos, :date
  end
end
