class AddServerJoinedAtColumnToMembersTable < ActiveRecord::Migration[7.2]
  def change
    add_column :members, :server_joined_at, :datetime
    add_index :members, :server_joined_at
  end
end
