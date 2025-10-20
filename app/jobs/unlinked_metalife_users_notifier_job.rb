class UnlinkedMetalifeUsersNotifierJob < ApplicationJob
  queue_as :default

  def perform(day: Date.yesterday)
    return if Oyasumi.oyasumi?(day)

    entered_user_ids = MetalifeEvent
      .where(event_type: 'enter')
      .where(occurred_at: day.all_day)
      .distinct
      .pluck(:metalife_user_id)

    unlinked_users = MetalifeUser
      .where(id: entered_user_ids)
      .where(linkable_id: nil)
      .order(:name)

    return if unlinked_users.empty?

    Notification.new.notify_unlinked_metalife_users(unlinked_users, day)
  end
end
