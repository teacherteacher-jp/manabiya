class CreateIntakeResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :intake_responses do |t|
      t.references :intake_session, null: false, foreign_key: true
      t.references :intake_item, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
