class MetalifeUser < ApplicationRecord
  belongs_to :linkable, polymorphic: true, optional: true

  validates :metalife_id, presence: true, uniqueness: true
  validates :name, presence: true

  after_create_commit :notify_created

  def notify_created
    Notification.new.notify_metalife_user_created(self)
  end

  def notify_school_entered(space_id)
    Notification.new.notify_metalife_user_school_entered(self, space_id)
  end
end
