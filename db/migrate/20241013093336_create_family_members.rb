class CreateFamilyMembers < ActiveRecord::Migration[7.2]
  def change
    create_table :family_members do |t|
      t.references :member, null: false, foreign_key: true
      t.integer :relationship, null: false
      t.boolean :cohabiting, default: true, null: false
      t.string :display_name
      t.date :birth_date

      t.timestamps
    end

    add_index :family_members, [:member_id, :cohabiting]
  end
end
