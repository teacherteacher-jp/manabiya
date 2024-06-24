class CreateMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :members do |t|
      t.string :name, limit: 32, null: false
      t.string :icon_url, limit: 2083, null: false
      t.string :discord_uid, limit: 32, null: false

      t.timestamps
    end

    add_index :members, :discord_uid, unique: true
  end
end
