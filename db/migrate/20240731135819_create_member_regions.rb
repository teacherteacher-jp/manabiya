class CreateMemberRegions < ActiveRecord::Migration[7.1]
  def change
    create_table :member_regions do |t|
      t.references :member, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true
      t.integer :category, null: false, default: 0

      t.timestamps
    end
  end
end
