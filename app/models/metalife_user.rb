class MetalifeUser < ApplicationRecord
  belongs_to :linkable, polymorphic: true, optional: true
  has_many :metalife_events, dependent: :destroy

  validates :metalife_id, presence: true, uniqueness: true
  validates :name, presence: true

  after_create_commit :notify_created

  def notify_created
    Notification.new.notify_metalife_user_created(self)
  end

  def notify_school_entered
    Notification.new.notify_metalife_user_school_entered(self)
  end
end
