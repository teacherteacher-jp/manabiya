class CreateSchoolMemos < ActiveRecord::Migration[8.0]
  def change
    create_table :school_memos do |t|
      t.references :member, null: false, foreign_key: true
      t.text :content, null: false, limit: 1000
      t.integer :category, null: false

      t.timestamps
    end
  end
end
