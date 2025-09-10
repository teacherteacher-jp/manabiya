class MetalifeEvent < ApplicationRecord
  belongs_to :metalife_user

  EVENT_TYPES = {
    enter: 'enter',
    leave: 'leave',
    enter_meeting: 'enterMeeting',
    leave_meeting: 'leaveMeeting',
    away: 'away',
    comeback: 'comeback',
    interphone: 'interphone',
    floor_move: 'floorMove',
    chat: 'chat'
  }.freeze

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES.values }
  validates :space_id, presence: true
  validates :occurred_at, presence: true

  before_validation :set_occurred_at

  private

  def set_occurred_at
    self.occurred_at ||= Time.at(payload['timestamp'].to_i / 1000.0) if payload&.dig('timestamp')
  end
end
