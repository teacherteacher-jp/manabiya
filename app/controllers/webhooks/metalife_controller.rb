class Webhooks::MetalifeController < WebhooksController
  def create
    content = "MetaLife: #{params[:text]}"

    token = Rails.application.credentials.dig(:discord_app, :bot_token)
    thread_id = Rails.application.credentials.dig(:discord, :community_center_thread_id)
    pp Discord::Bot.new(token).send_message(channel_or_thread_id: thread_id, content:)

    render json: { message: "ok" }, status: :ok
  end
end
