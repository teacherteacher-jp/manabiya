require "minitest/autorun"

describe Member do
  describe "generation" do
    it "2023年11月加入なら、1期生" do
      member = Member.new(server_joined_at: "2023-11-01")
      _(member.generation).must_equal(1)
    end

    it "2023年12月1日加入なら、1期生" do
      member = Member.new(server_joined_at: "2023-12-01")
      _(member.generation).must_equal(1)
    end

    it "2024年1月1日加入なら、2期生" do
      member = Member.new(server_joined_at: "2024-01-01")
      _(member.generation).must_equal(2)
    end

    it "2024年9月1日加入なら、10期生" do
      member = Member.new(server_joined_at: "2024-09-01")
      _(member.generation).must_equal(10)
    end
  end
end
