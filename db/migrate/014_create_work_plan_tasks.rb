class CreateWorkPlanTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :work_plan_tasks do |t|
      t.references :work_plan_category, null: false, foreign_key: { to_table: :work_plan_categories }
      t.references :issue, null: false, foreign_key: { to_table: :issues }
      t.decimal :total_hours, precision: 15, scale: 2, default: 0
      t.integer :accounting_month # Месяц учета (1-12)
      t.integer :report_inclusion_month # Месяц включения в отчет (1-12)
      t.text :comments
      t.text :result # Ожидаемый результат

      t.timestamps
    end

    add_index :work_plan_tasks, [:work_plan_category_id, :issue_id], unique: true, name: 'unique_issue_in_work_plan_category'
    add_index :work_plan_tasks, :accounting_month
    add_index :work_plan_tasks, :report_inclusion_month
  end
end