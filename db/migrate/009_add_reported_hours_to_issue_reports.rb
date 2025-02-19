# db/migrate/009_add_reported_hours_to_issue_reports.rb
class AddReportedHoursToIssueReports < ActiveRecord::Migration[5.2]
  def change
    add_column :issue_reports, :reported_hours, :decimal, precision: 15, scale: 2
  end
end