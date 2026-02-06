class MigrateParentMemberToGuardianships < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      INSERT INTO guardianships (student_id, member_id, created_at, updated_at)
      SELECT id, parent_member_id, created_at, created_at
      FROM students
      WHERE parent_member_id IS NOT NULL
    SQL
  end

  def down
    execute <<-SQL
      UPDATE students
      SET parent_member_id = (
        SELECT member_id FROM guardianships
        WHERE guardianships.student_id = students.id
        ORDER BY guardianships.created_at ASC
        LIMIT 1
      )
    SQL
  end
end
