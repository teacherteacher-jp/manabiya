require 'test_helper'

class OyasumiTest < ActiveSupport::TestCase
  test "水曜日はお休み" do
    wednesday = Date.new(2025, 7, 23)
    assert Oyasumi.oyasumi?(wednesday)
  end

  test "土曜日はお休み" do
    saturday = Date.new(2025, 7, 26)
    assert Oyasumi.oyasumi?(saturday)
  end

  test "日曜日はお休み" do
    sunday = Date.new(2025, 7, 27)
    assert Oyasumi.oyasumi?(sunday)
  end

  test "祝日はお休み" do
    # 海の日
    marine_day = Date.new(2025, 7, 21)
    assert Oyasumi.oyasumi?(marine_day)
  end

  test "休暇期間中はお休み" do
    vacation_date = Date.new(2025, 7, 18)
    assert Oyasumi.oyasumi?(vacation_date)
  end

  test "平日で祝日でも休暇期間でもない場合はお休みではない" do
    regular_monday = Date.new(2025, 9, 1)
    assert_not Oyasumi.oyasumi?(regular_monday)
  end

  test "vacation?は休暇期間中の日付でtrueを返す" do
    vacation_date = Date.new(2025, 7, 20)
    assert Oyasumi.vacation?(vacation_date)
  end

  test "vacation?は休暇期間外の日付でfalseを返す" do
    non_vacation_date = Date.new(2025, 9, 15)
    assert_not Oyasumi.vacation?(non_vacation_date)
  end

  test "current_vacation_periodは休暇期間中の日付に対して休暇情報を返す" do
    # 夏休み期間中の日付でテスト
    vacation_date = Date.new(2025, 7, 20)
    result = Oyasumi.current_vacation_period(vacation_date)

    assert_not_nil result
    assert_instance_of Hash, result
    assert_equal Date.new(2025, 7, 18), result[:start_date]
    assert_equal Date.new(2025, 8, 26), result[:end_date]
    assert_equal "コンコンは7/18(金)から8/26(火)までお休みです", result[:message]
  end

  test "current_vacation_periodは休暇期間外の日付に対してnilを返す" do
    # 休暇期間外の日付でテスト
    non_vacation_date = Date.new(2025, 9, 1)
    assert_nil Oyasumi.current_vacation_period(non_vacation_date)
  end

  test "vacationsはvacations.txtから日付を正しく読み込む" do
    vacations = Oyasumi.vacations

    assert_instance_of Array, vacations
    assert_includes vacations, Date.new(2025, 7, 18)
    assert_includes vacations, Date.new(2025, 8, 26)
    # 2024年のクリスマス休暇
    assert_includes vacations, Date.new(2024, 12, 24)
  end

  test "load_vacationsは無効な日付をスキップする" do
    vacations = Oyasumi.vacations

    vacations.each do |vacation|
      assert_instance_of Date, vacation
    end
  end

  test "group_consecutive_datesは連続する日付をグループ化する" do
    dates = [
      Date.new(2025, 7, 18),
      Date.new(2025, 7, 19),
      Date.new(2025, 7, 20),
      Date.new(2025, 7, 25),
      Date.new(2025, 7, 26)
    ]

    ranges = Oyasumi.send(:group_consecutive_dates, dates)

    assert_equal 2, ranges.size
    assert_equal Date.new(2025, 7, 18)..Date.new(2025, 7, 20), ranges[0]
    assert_equal Date.new(2025, 7, 25)..Date.new(2025, 7, 26), ranges[1]
  end

  test "group_consecutive_datesは空の配列に対して空の配列を返す" do
    assert_equal [], Oyasumi.send(:group_consecutive_dates, [])
  end

  test "build_vacation_messageは日本語の曜日でメッセージを生成する" do
    start_date = Date.new(2025, 7, 18) # 金曜日
    end_date = Date.new(2025, 8, 26)   # 火曜日

    message = Oyasumi.send(:build_vacation_message, start_date, end_date)

    assert_equal "コンコンは7/18(金)から8/26(火)までお休みです", message
  end
end
