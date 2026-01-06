class AddReportFormatToIntakes < ActiveRecord::Migration[8.1]
  def change
    add_column :intakes, :report_format, :text
  end
end
