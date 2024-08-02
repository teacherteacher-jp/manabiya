class CreateRegions < ActiveRecord::Migration[7.1]
  def change
    create_table :regions do |t|
      t.string :code, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :regions, :code, unique: true
    add_index :regions, :name
  end
end
