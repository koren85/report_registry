# db/migrate/008_change_report_title_to_text.rb
class ChangeReportTitleToText < ActiveRecord::Migration[5.2]
  def change
    # Меняем тип поля с string (varchar) на text для хранения длинного текста
    change_column :issue_reports, :report_title, :text
  end
end