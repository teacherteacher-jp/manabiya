require "minitest/autorun"
require "active_support/testing/time_helpers"

describe FamilyMember do
  include ActiveSupport::Testing::TimeHelpers

  describe "age and school_grade_jp" do
    it "生年月日がnilの場合はnilを返す" do
      family_member = FamilyMember.new
      _(family_member.age).must_be_nil
    end

    it "1983年6月29日生まれの人は、2024年10月13日には41歳で、小中学生ではない" do
      family_member = FamilyMember.new(birth_date: "1983-06-29")

      travel_to("2024-10-13") do
        _(family_member.age).must_equal(41)
        _(family_member.school_grade_jp).must_be_nil
      end
    end

    it "2009年4月1日生まれの人は、2024年10月13日には15歳で、小中学生ではない" do
      family_member = FamilyMember.new(birth_date: "2009-04-01")

      travel_to("2024-10-13") do
        _(family_member.age).must_equal(15)
        _(family_member.school_grade_jp).must_be_nil
      end
    end

    it "2009年4月2日生まれの人は、2024年10月13日には15歳で、中学校3年生" do
      family_member = FamilyMember.new(birth_date: "2009-04-02")

      travel_to("2024-10-13") do
        _(family_member.age).must_equal(15)
        _(family_member.school_grade_jp).must_equal("中学3年生")
      end
    end

    it "2017年4月1日生まれの人は、2024年10月13日には7歳で、小学校2年生" do
      family_member = FamilyMember.new(birth_date: "2017-04-01")

      travel_to("2024-10-13") do
        _(family_member.age).must_equal(7)
        _(family_member.school_grade_jp).must_equal("小学2年生")
      end
    end

    it "2017年4月2日生まれの人は、2024年10月13日には7歳で、小学校1年生" do
      family_member = FamilyMember.new(birth_date: "2017-04-02")

      travel_to("2024-10-13") do
        _(family_member.age).must_equal(7)
        _(family_member.school_grade_jp).must_equal("小学1年生")
      end
    end

    it "2018年4月2日生まれの人は、2024年10月13日には6歳で、小中学生ではない" do
      family_member = FamilyMember.new(birth_date: "2018-04-02")

      travel_to("2024-10-13") do
        _(family_member.age).must_equal(6)
        _(family_member.school_grade_jp).must_be_nil
      end
    end

    it "2018年4月2日生まれの人は、2025年4月1日には6歳で、小学1年生" do
      family_member = FamilyMember.new(birth_date: "2018-04-02")

      travel_to("2025-04-01") do
        _(family_member.age).must_equal(6)
        _(family_member.school_grade_jp).must_equal("小学1年生")
      end
    end

    it "2018年4月2日生まれのペットは、2025年4月1日には6歳で、小中学生ではない" do
      family_member = FamilyMember.new(birth_date: "2018-04-02", relationship: "pet")

      travel_to("2025-04-01") do
        _(family_member.age).must_equal(6)
        _(family_member.school_grade_jp).must_be_nil
      end
    end
  end
end
