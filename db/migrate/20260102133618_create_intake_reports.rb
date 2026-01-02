class CreateIntakeReports < ActiveRecord::Migration[8.1]
  def change
    create_table :intake_reports do |t|
      t.references :intake_session, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
