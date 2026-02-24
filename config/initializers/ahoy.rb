class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:member_id] = current_member&.id
    super(data)
  end

  def track_event(data)
    data[:member_id] = current_member&.id
    super(data)
  end

  def authenticate(_)
    if visit && !visit.member && current_member
      visit.update!(member: current_member)
    end
  end

  private

  def current_member
    controller&.current_member
  end
end

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false

# falseにすると意図せず除外されちゃうやつがあるので
Ahoy.track_bots = true
