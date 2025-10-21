module MetalifeEventsHelper
  def event_type_label(event_type)
    labels = {
      'enter' => '入室',
      'leave' => '退室',
      'enterMeeting' => '会議室入室',
      'leaveMeeting' => '会議室退室',
      'away' => '離席',
      'comeback' => '戻り',
      'interphone' => 'インターホン',
      'floorMove' => 'フロア移動',
      'chat' => 'チャット'
    }
    labels[event_type] || event_type
  end

  def event_badge_class(event_type)
    classes = {
      'enter' => 'bg-green-100 text-green-800',
      'leave' => 'bg-red-100 text-red-800',
      'enterMeeting' => 'bg-blue-100 text-blue-800',
      'leaveMeeting' => 'bg-blue-50 text-blue-600',
      'away' => 'bg-yellow-100 text-yellow-800',
      'comeback' => 'bg-green-50 text-green-600',
      'interphone' => 'bg-purple-100 text-purple-800',
      'floorMove' => 'bg-indigo-100 text-indigo-800',
      'chat' => 'bg-gray-100 text-gray-800'
    }
    classes[event_type] || 'bg-gray-100 text-gray-800'
  end

  def event_icon(event_type)
    icons = {
      'enter' => '🚪',
      'leave' => '👋',
      'enterMeeting' => '🏢',
      'leaveMeeting' => '🚶',
      'away' => '☕️',
      'comeback' => '↩️',
      'interphone' => '🔔',
      'floorMove' => '🔄',
      'chat' => '💬'
    }
    content_tag(:span, icons[event_type] || '📌', class: 'text-lg')
  end
end
