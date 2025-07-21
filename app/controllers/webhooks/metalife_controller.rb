class Webhooks::MetalifeController < WebhooksController
  def create
    space_id = params[:spaceId]

    case space_id
    when Rails.application.credentials.dig(:metalife, :school_space_id)
      metalife_user = MetalifeUser.find_or_initialize_by(metalife_id: params[:id])
      metalife_user.update!(name: params[:name])

      handle_school_space_event(metalife_user, params)
    when Rails.application.credentials.dig(:metalife, :community_center_space_id)
      handle_community_center_event(params)
    end

    render json: { message: "ok" }, status: :ok
  end

  private

  def handle_school_space_event(metalife_user, params)
    return unless params[:when] == "enter"

    if metalife_user.linkable
      metalife_user.notify_school_entered(params[:spaceId])
    end
  end

  def handle_community_center_event(params)
    content = params[:text]
    content += "\n<https://app.metalife.co.jp/spaces/%s>" % [params[:spaceId]] if params[:when] == "enter"

    token = Rails.application.credentials.dig(:discord_app, :bot_token)
    thread_id = Rails.application.credentials.dig(:discord, :community_center_thread_id)
    Discord::Bot.new(token).send_message(channel_or_thread_id: thread_id, content:)
  end
end
