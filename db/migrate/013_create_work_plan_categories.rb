class CreateWorkPlanCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :work_plan_categories do |t|
      t.references :work_plan, null: false, foreign_key: { to_table: :work_plans }
      t.integer :plan_work_id # Связь с PlanWork из westaco_versions
      t.string :category_name, null: false
      t.decimal :planned_hours, precision: 15, scale: 2, default: 0

      t.timestamps
    end

    add_index :work_plan_categories, [:work_plan_id, :plan_work_id], unique: true, name: 'unique_plan_work_in_category'
  end
end