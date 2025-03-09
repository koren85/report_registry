class CreateReportPlanLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :report_plan_links do |t|
      t.references :report, null: false, foreign_key: { to_table: :reports }
      t.references :work_plan_task, null: false, foreign_key: { to_table: :work_plan_tasks }
      t.decimal :reported_hours, precision: 15, scale: 2
      t.string :status, default: 'запланировано' # запланировано, включено, перенесено

      t.timestamps
    end

    add_index :report_plan_links, [:report_id, :work_plan_task_id], unique: true, name: 'unique_task_in_report_plan'
  end
end