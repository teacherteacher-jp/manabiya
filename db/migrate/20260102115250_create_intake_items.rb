class CreateIntakeItems < ActiveRecord::Migration[8.1]
  def change
    create_table :intake_items do |t|
      t.references :intake, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 0, null: false

      t.timestamps
    end
  end
end
