class Webhooks::MetalifeController < WebhooksController
  def create
    space_id = params[:spaceId]
    school_space_id = Rails.application.credentials.dig(:metalife, :school_space_id)
    community_center_space_id = Rails.application.credentials.dig(:metalife, :community_center_space_id)

    case space_id
    when school_space_id
      handle_school_event(params)
    when community_center_space_id
      handle_community_center_event(params)
    end

    render json: { message: "ok" }, status: :ok
  end

  private

  def handle_school_event(params)
    # コンコン(school_space_id)の場合のみMetalifeUserを管理
    metalife_user = MetalifeUser.find_or_initialize_by(metalife_id: params[:id])
    metalife_user.update!(name: params[:name])

    save_metalife_event(metalife_user, params)
  end

  def handle_community_center_event(params)
    content = params[:text]
    content += "\n<https://app.metalife.co.jp/spaces/%s>" % [params[:spaceId]] if params[:when] == "enter"

    token = Rails.application.credentials.dig(:discord_app, :bot_token)
    thread_id = Rails.application.credentials.dig(:discord, :community_center_thread_id)
    Discord::Bot.new(token).send_message(channel_or_thread_id: thread_id, content:)
  end

  def save_metalife_event(metalife_user, params)
    MetalifeEvent.create!(
      metalife_user: metalife_user,
      event_type: params[:when],
      space_id: params[:spaceId],
      floor_id: params[:floorId],
      message: params[:text],
      payload: params.to_unsafe_h
    )
  rescue => e
    Rails.logger.error "Failed to save MetaLife event: #{e.message}"
  end
end
