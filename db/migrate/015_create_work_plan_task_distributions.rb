class CreateWorkPlanTaskDistributions < ActiveRecord::Migration[5.2]
  def change
    create_table :work_plan_task_distributions do |t|
      t.references :work_plan_task, null: false, foreign_key: { to_table: :work_plan_tasks }
      t.integer :month, null: false # Номер месяца (1-12)
      t.decimal :hours, precision: 15, scale: 2, default: 0

      t.timestamps
    end

    add_index :work_plan_task_distributions, [:work_plan_task_id, :month], unique: true, name: 'unique_month_in_work_plan_task'
  end
end