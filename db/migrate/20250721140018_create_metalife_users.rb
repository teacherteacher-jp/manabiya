class CreateMetalifeUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :metalife_users do |t|
      t.string :metalife_id
      t.string :name
      t.references :linkable, polymorphic: true

      t.timestamps
    end
    add_index :metalife_users, :metalife_id, unique: true
  end
end
