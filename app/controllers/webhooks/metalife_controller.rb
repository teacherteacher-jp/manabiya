class Webhooks::MetalifeController < WebhooksController
  def create
    content = params[:text]
    content += "\n<%s>" % [ENV["COMMUNITY_CENTER_URL"]] if content.include?("入室しました")

    if params[:spaceId] == Rails.application.credentials.dig(:metalife, :community_center_space_id)
      token = Rails.application.credentials.dig(:discord_app, :bot_token)
      thread_id = Rails.application.credentials.dig(:discord, :community_center_thread_id)
      pp Discord::Bot.new(token).send_message(channel_or_thread_id: thread_id, content:)
    end

    puts "{ space_id: '%s', session_id: '%s', name: '%s' }" % [params[:spaceId], params[:id], params[:name]]

    render json: { message: "ok" }, status: :ok
  end
end
