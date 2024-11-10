class AddAdminColumnToMembersTable < ActiveRecord::Migration[7.2]
  def change
    add_column :members, :admin, :boolean, default: false
  end
end
