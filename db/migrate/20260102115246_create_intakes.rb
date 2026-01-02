class CreateIntakes < ActiveRecord::Migration[8.1]
  def change
    create_table :intakes do |t|
      t.string :title, null: false
      t.text :description

      t.timestamps
    end
  end
end
