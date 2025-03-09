# app/models/work_plan_task_distribution.rb
class WorkPlanTaskDistribution < ActiveRecord::Base
  belongs_to :work_plan_task

  validates :month, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :hours, numericality: { greater_than: 0 }
  validates :month, uniqueness: { scope: :work_plan_task_id, message: :error_month_already_exists }

  # Получить имя месяца
  def month_name
    I18n.t('date.month_names')[month]
  end

  # Получить название месяца с годом
  def month_year_name
    year = work_plan_task.work_plan_category.work_plan.year
    "#{month_name} #{year}"
  end

  # Получить дату начала месяца
  def start_date
    year = work_plan_task.work_plan_category.work_plan.year
    Date.new(year, month, 1)
  end

  # Получить дату окончания месяца
  def end_date
    start_date.end_of_month
  end
end