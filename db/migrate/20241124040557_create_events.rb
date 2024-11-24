class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.datetime :start_at, null: false
      t.string :venue, null: false
      t.string :source_link, null: false

      t.timestamps

      t.index :start_at
    end
  end
end
