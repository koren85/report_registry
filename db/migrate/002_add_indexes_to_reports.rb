# plugins/report_registry/db/migrate/002_add_indexes_to_reports.rb
class AddIndexesToReports < ActiveRecord::Migration[5.2]
  def change
    # Индексы для сортировки
    add_index :reports, :created_at
    add_index :reports, :updated_at

    # Индексы для фильтрации
    add_index :reports, :period
    add_index :reports, :status
    add_index :reports, :start_date
    add_index :reports, :end_date
    add_index :reports, :contract_number
    add_index :reports, :created_by
    add_index :reports, :updated_by

    # Объединённые индексы
    add_index :reports, [:start_date, :end_date], name: 'index_reports_on_date_range'
    add_index :reports, [:created_by, :status], name: 'index_reports_on_creator_and_status'
  end
end
