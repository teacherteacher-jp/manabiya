class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title
      t.text :description
      t.datetime :start_at
      t.string :venue
      t.string :source_link

      t.timestamps
    end
  end
end
