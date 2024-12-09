# plugins/report_registry/db/migrate/004_add_project_and_version_to_reports.rb
class AddProjectAndVersionToReports < ActiveRecord::Migration[5.2]
  def change
    add_reference :reports, :version, foreign_key: { to_table: :versions }
  end
end
