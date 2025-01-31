class Webhooks::MetalifeController < WebhooksController
  def create
    space_id = params[:spaceId]
    content = params[:text]
    content += "\n<https://app.metalife.co.jp/spaces/%s>" % [space_id] if content.include?("入室しました")

    if space_id == Rails.application.credentials.dig(:metalife, :community_center_space_id)
      token = Rails.application.credentials.dig(:discord_app, :bot_token)
      thread_id = Rails.application.credentials.dig(:discord, :community_center_thread_id)
      pp Discord::Bot.new(token).send_message(channel_or_thread_id: thread_id, content:)
    end

    puts "{ space_id: '%s', session_id: '%s', name: '%s' }" % [space_id, params[:id], params[:name]]

    render json: { message: "ok" }, status: :ok
  end
end
