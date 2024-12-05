# plugins/report_registry/db/migrate/001_create_reports.rb
class CreateReports < ActiveRecord::Migration[5.2]
  def change
    create_table :reports do |t|
      t.string :name, null: false
      t.string :period
      t.date :start_date
      t.date :end_date
      t.string :status, null: false, default: 'черновик'
      t.integer :created_by, null: false
      t.integer :updated_by
      t.integer :total_hours
      t.string :contract_number
      t.timestamps
    end
  end
end
