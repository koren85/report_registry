class CreateWorkPlans < ActiveRecord::Migration[5.2]
  def change
    create_table :work_plans do |t|
      t.string :name, null: false
      t.integer :year, null: false
      t.string :status, default: 'черновик', null: false
      t.text :notes
      t.references :version, foreign_key: { to_table: :versions }
      t.integer :created_by, null: false
      t.integer :updated_by

      t.timestamps
    end

    add_index :work_plans, :year
    add_index :work_plans, :status
    add_index :work_plans, :created_by
    add_index :work_plans, :updated_by
    add_index :work_plans, [:version_id], unique: true, name: 'unique_version_in_work_plan'
  end
end