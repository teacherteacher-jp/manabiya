class FamilyMember < ApplicationRecord
  belongs_to :member

  enum :relationship, {
    wife: 0,
    husband: 1,
    daughter: 2,
    son: 3,
    mother: 4,
    father: 5,
    mother_in_law: 6,
    father_in_law: 7,
    older_sister: 8,
    older_brother: 9,
    younger_sister: 10,
    younger_brother: 11,
    partner: 12,
    pet: 90,
    other: 99
  }

  validates :relationship, presence: true

  before_save :normalize_display_name
  after_create_commit :notify

  class << self
    def relationship_in_japanese
      {
        wife: "妻", 
        husband: "夫",
        daughter: "娘",
        son: "息子",
        mother: "母",
        father: "父",
        mother_in_law: "義母",
        father_in_law: "義父",
        older_sister: "姉",
        older_brother: "兄",
        younger_sister: "妹",
        younger_brother: "弟",
        partner: "パートナー",
        pet: "ペット",
        other: "その他",
      }
    end

    def relationship_options
      relationships.map { [FamilyMember.relationship_in_japanese[_1[0].to_sym], _1[0]] }
    end
  end

  def relationship_in_japanese
    FamilyMember.relationship_in_japanese[relationship.to_sym]
  end

  def normalize_display_name
    self.display_name = nil if display_name.blank?
  end

  def age
    return nil if birth_date.nil?

    date = Date.today
    count = 0

    loop do
      date = date.prev_year
      break if date < birth_date
      count += 1
    end

    count
  end

  def school_grade_jp
    return if relationship == "pet"
    return if birth_date.nil?

    today = Date.today
    school_year_ranges = {
      "小学1年生": Date.new(today.year - 7, 4, 2)..Date.new(today.year - 6, 4, 1),
      "小学2年生": Date.new(today.year - 8, 4, 2)..Date.new(today.year - 7, 4, 1),
      "小学3年生": Date.new(today.year - 9, 4, 2)..Date.new(today.year - 8, 4, 1),
      "小学4年生": Date.new(today.year - 10, 4, 2)..Date.new(today.year - 9, 4, 1),
      "小学5年生": Date.new(today.year - 11, 4, 2)..Date.new(today.year - 10, 4, 1),
      "小学6年生": Date.new(today.year - 12, 4, 2)..Date.new(today.year - 11, 4, 1),
      "中学1年生": Date.new(today.year - 13, 4, 2)..Date.new(today.year - 12, 4, 1),
      "中学2年生": Date.new(today.year - 14, 4, 2)..Date.new(today.year - 13, 4, 1),
      "中学3年生": Date.new(today.year - 15, 4, 2)..Date.new(today.year - 14, 4, 1),
    }

    school_year_ranges.each do |grade, range|
      return grade.to_s if range.cover?(birth_date)
    end
  
    nil
  end

  def order_score
    score = 0
    score += 100000 if cohabiting
    score += 10000 if relationship != "pet"
    score += (1000 - age.to_i)

    score * -1
  end

  def notify
    Notification.new.notify_family_member_created(self)
  end
end
