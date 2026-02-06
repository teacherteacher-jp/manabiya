require "test_helper"

class MemberCanAccessStudentInfoTest < ActiveSupport::TestCase
  def create_member(admin: false)
    # server_joined_at を設定して fill_server_joined_at コールバックの Discord API 呼び出しを回避
    Member.create!(
      discord_uid: SecureRandom.hex(8),
      name: "テストメンバー",
      icon_url: "https://example.com/icon.png",
      server_joined_at: Time.current,
      admin: admin
    )
  end

  def create_student
    # insert! で after_create_commit の通知コールバックを回避
    result = Student.insert!({
      name: "テスト生徒",
      grade: Student.grades["小学校1年生"],
      created_at: Time.current,
      updated_at: Time.current
    })
    Student.find(result.rows.first.first)
  end

  test "adminはアクセスできる" do
    member = create_member(admin: true)
    assert member.can_access_student_info?
  end

  test "保護者はアクセスできる" do
    member = create_member
    student = create_student
    Guardianship.create!(member: member, student: student)
    assert member.can_access_student_info?
  end

  test "最近のボランティア担当があればアクセスできる" do
    member = create_member
    schedule = Schedule.create!(member: member, date: Date.today, status: :ok, slot: :s1)
    # insert! で after_create_commit の通知コールバックを回避
    Assignment.insert!({ schedule_id: schedule.id, created_at: Time.current, updated_at: Time.current })
    assert member.can_access_student_info?
  end

  test "上記のいずれにも該当しなければアクセスできない" do
    member = create_member
    refute member.can_access_student_info?
  end
end
