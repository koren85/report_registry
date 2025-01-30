# db/migrate/007_add_report_title_to_issue_reports.rb
class AddReportTitleToIssueReports < ActiveRecord::Migration[5.2]
  def change
    add_column :issue_reports, :report_title, :string
  end
end