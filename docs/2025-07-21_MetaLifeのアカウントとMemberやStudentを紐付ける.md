# MetaLifeのアカウントと、ManabiyaのMember/Studentを紐付けたい

以下、前提情報。

- オンラインスクールのフリースクール「コンコン」の運営を支援する、Manabiyaというアプリケーションを開発している
- コンコンは、MetaLifeという2次元空間をデザインできるサービス上に教室がある
- ManabiyaのMemberやStudentをMetaLifeのアカウントと紐付けることで、種々の便利機能を追加できるようになる
  - Member: コンコンに子を通わせる保護者やボランティアで関わる人など、Discord認証でログインする
  - Student: コンコンに通う生徒で、生徒たちがManabiyaにログインすることはなく、MemberがStudentに対してメモを書いたりできる

## 今回やろうとしていること

- MetaLifeのWebhookをManabiyaで受け取ることで、段階的にアカウントの紐付けを行っていきたい
  - https://support.metalife.co.jp/44363d6b05554ca2b0090e52eafb491e
- MetaLifeのWebhookでMetaLifeアカウントのidを受け取るたびに、Manabiyaのデータベースに「MetalifeUser」モデルのレコードとして保存する
- Manabiyaの管理者は、MetalifeUserに対して、MemberもしくはStudentのレコードを1:1で紐付けることができる
- 紐付けが完了したMetalifeUserに関しては「Student(id:5)がコンコンの教室に入室しました」をDiscord通知したりできるようになる

## 備考

- われわれが運営しているMetaLifeのスペースはふたつある
  - ひとつは「コンコン」 `Rails.application.credentials.dig(:metalife, :school_space_id)`
  - もうひとつは「公民館」 `Rails.application.credentials.dig(:metalife, :community_center_space_id)`
- すでに app/controllers/webhooks/metalife_controller.rb が存在している
  - これは公民館の「入室イベント」のWebhookを受け取ってDiscordに通知している
  - 今回、あらたにコンコンのWebhookをハンドリングする処理を実装したい、ということ

## 設計案

### 1. MetalifeUserモデル

```ruby
class MetalifeUser < ApplicationRecord
  # ポリモーフィック関連付けでMemberまたはStudentと紐付け
  belongs_to :linkable, polymorphic: true, optional: true

  validates :metalife_id, presence: true, uniqueness: true
  validates :name, presence: true

  # スペースをまたいで同じmetalife_idを持つため、space_idは不要
  # 複数のスペースでの活動はWebhookイベント時に判別

  after_create_commit :notify_created

  def notify_created
    Notification.new.notify_metalife_user_created(self)
  end

  def notify_school_entered(space_id)
    Notification.new.notify_metalife_user_school_entered(self, space_id)
  end
end
```

### 2. Member/Studentモデルへの関連追加

```ruby
# app/models/member.rb
class Member < ApplicationRecord
  has_one :metalife_user, as: :linkable, dependent: :nullify
  # 既存のコード...
end

# app/models/student.rb
class Student < ApplicationRecord
  has_one :metalife_user, as: :linkable, dependent: :nullify
  # 既存のコード...
end
```

### 3. マイグレーション

```ruby
class CreateMetalifeUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :metalife_users do |t|
      t.string :metalife_id, null: false
      t.string :name, null: false
      t.references :linkable, polymorphic: true, null: true

      t.timestamps
    end

    add_index :metalife_users, :metalife_id, unique: true
  end
end
```

### 4. Webhookコントローラーの拡張

```ruby
class Webhooks::MetalifeController < WebhooksController
  def create
    space_id = params[:spaceId]

    # MetalifeUserの作成または更新
    metalife_user = MetalifeUser.find_or_initialize_by(metalife_id: params[:id])
    metalife_user.update!(name: params[:name])

    # スペースごとの処理
    case space_id
    when Rails.application.credentials.dig(:metalife, :school_space_id)
      handle_school_space_event(metalife_user, params)
    when Rails.application.credentials.dig(:metalife, :community_center_space_id)
      handle_community_center_event(params)
    end

    render json: { message: "ok" }, status: :ok
  end

  private

  def handle_school_space_event(metalife_user, params)
    return unless params[:text].include?("入室しました")

    # 紐付けられたMember/Studentがある場合のみ詳細な通知
    # 紐付けがない場合はMetalifeUserの保存のみ（通知はしない）
    if metalife_user.linkable.present?
      metalife_user.notify_school_entered(params[:spaceId])
    end
  end

  def handle_community_center_event(params)
    # 既存の処理をそのまま実行
    content = params[:text]
    content += "\n<https://app.metalife.co.jp/spaces/%s>" % [params[:spaceId]] if content.include?("入室しました")

    token = Rails.application.credentials.dig(:discord_app, :bot_token)
    thread_id = Rails.application.credentials.dig(:discord, :community_center_thread_id)
    Discord::Bot.new(token).send_message(channel_or_thread_id: thread_id, content:)
  end
end
```

### 5. Notificationクラスへの追加

```ruby
class Notification
  # 既存のメソッド...

  def notify_metalife_user_created(metalife_user)
    content = "新しいMetaLifeユーザーが検出されました\n" \
              "ID: #{metalife_user.metalife_id}\n" \
              "名前: #{metalife_user.name}"

    thread_id = Rails.application.credentials.dig(:discord, :admin_school_thread_id)
    send_to_discord(thread_id, content)
  end

  def notify_metalife_user_school_entered(metalife_user, space_id)
    linkable = metalife_user.linkable
    type = linkable.is_a?(Student) ? "生徒" : "メンバー"

    content = "#{type}（#{linkable.name}）がコンコンの教室に入室しました\n" \
              "<https://app.metalife.co.jp/spaces/#{space_id}>"

    thread_id = Rails.application.credentials.dig(:discord, :school_thread_id)
    send_to_discord(thread_id, content)
  end

  private

  def send_to_discord(channel_or_thread_id, content)
    token = Rails.application.credentials.dig(:discord_app, :bot_token)
    Discord::Bot.new(token).send_message(channel_or_thread_id:, content:)
  end
end
```

### 6. 管理画面での紐付け機能

`/metalife_users` ページを作成し、`current_user.admin?` で認可：

#### コントローラー
```ruby
class MetalifeUsersController < ApplicationController
  before_action :require_admin

  def index
    @metalife_users = MetalifeUser.includes(:linkable).order(created_at: :desc)
  end

  def update
    @metalife_user = MetalifeUser.find(params[:id])

    if params[:linkable_type].present? && params[:linkable_id].present?
      linkable = params[:linkable_type].constantize.find(params[:linkable_id])
      @metalife_user.update!(linkable: linkable)
    else
      @metalife_user.update!(linkable: nil)
    end

    redirect_to metalife_users_path, notice: "紐付けを更新しました"
  end

  private

  def require_admin
    redirect_to root_path unless current_user&.admin?
  end
end
```

#### ビュー (index.html.erb)
```erb
<h1>MetaLifeユーザー管理</h1>

<table>
  <thead>
    <tr>
      <th>MetaLife ID</th>
      <th>名前</th>
      <th>紐付け先</th>
      <th>作成日時</th>
      <th>操作</th>
    </tr>
  </thead>
  <tbody>
    <% @metalife_users.each do |user| %>
      <tr>
        <td><%= user.metalife_id %></td>
        <td><%= user.name %></td>
        <td>
          <% if user.linkable.present? %>
            <%= user.linkable.class.name %>: <%= user.linkable.name %>
          <% else %>
            未紐付け
          <% end %>
        </td>
        <td><%= user.created_at.strftime("%Y-%m-%d %H:%M") %></td>
        <td>
          <%= form_with url: metalife_user_path(user), method: :patch do |f| %>
            <%= f.select :linkable_type, options_for_select([["", ""], ["Member", "Member"], ["Student", "Student"]], user.linkable_type) %>
            <%= f.select :linkable_id, options_for_select([]) %>
            <%= f.submit "更新" %>
          <% end %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

### 検討事項

1. **紐付けのタイミング**

- 管理者による手動紐付けのみ？
- 将来的に自動紐付け（例：Discordアカウントとの連携）も検討？

→ 手動の紐付けだけ考えておけば十分

2. **履歴管理**

- MetalifeUserの入退室履歴を保存する必要があるか？
- 紐付けの変更履歴を保存する必要があるか？

→ 今のところは、履歴は保存しなくてよい
