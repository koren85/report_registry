class CreateIssueReports < ActiveRecord::Migration[5.2]
  def change
    create_table :issue_reports do |t|
      t.references :issue, null: false, foreign_key: { to_table: :issues }
      t.references :report, null: false, foreign_key: { to_table: :reports }
      t.timestamps
    end

    # Уникальный индекс на пары issue-report
    add_index :issue_reports, [:issue_id, :report_id], unique: true
  end
end