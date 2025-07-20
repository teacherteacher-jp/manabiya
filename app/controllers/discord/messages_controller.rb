require "ostruct"

class Discord::MessagesController < ApplicationController
  def new
    @message = OpenStruct.new(channel_id: "", content: "")
  end

  def create
    bot_token = Rails.application.credentials.dig("discord_app", "bot_token")
    bot = ::Discord::Bot.new(bot_token)

    result = bot.send_message(
      channel_or_thread_id: params[:channel_id],
      content: params[:content]
    )

    pp result

    if result["id"]
      redirect_to new_discord_message_path, notice: "メッセージを送信しました"
    else
      @message = OpenStruct.new(channel_id: params[:channel_id], content: params[:content])
      flash.now[:alert] = "メッセージの送信に失敗しました: #{result["message"] || "不明なエラー"}"
      render :new, status: :unprocessable_entity
    end
  rescue => e
    @message = OpenStruct.new(channel_id: params[:channel_id], content: params[:content])
    flash.now[:alert] = "エラーが発生しました: #{e.message}"
    render :new, status: :unprocessable_entity
  end
end
