# db/migrate/011_add_period_details_to_reports.rb
class AddPeriodDetailsToReports < ActiveRecord::Migration[5.2]
  def change
    add_column :reports, :selected_month, :integer
    add_column :reports, :selected_quarter, :integer
    add_column :reports, :selected_year, :integer
  end
end