# plugins/report_registry/db/migrate/003_add_project_to_reports.rb
class AddProjectToReports < ActiveRecord::Migration[5.2]
  def change
    add_reference :reports, :project, null: false, foreign_key: { to_table: :projects }
  end
end
