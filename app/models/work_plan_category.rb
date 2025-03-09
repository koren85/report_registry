# app/models/work_plan_category.rb
class WorkPlanCategory < ActiveRecord::Base
  belongs_to :work_plan
  has_many :work_plan_tasks, dependent: :destroy

  validates :category_name, presence: true
  validates :planned_hours, numericality: { greater_than_or_equal_to: 0 }
  validates :plan_work_id, uniqueness: { scope: :work_plan_id, message: :error_category_already_exists }, allow_nil: true

  before_save :update_planned_hours

  # Обновляем сумму запланированных часов на основе задач в категории
  def update_planned_hours
    self.planned_hours = work_plan_tasks.sum(:total_hours)
  end

  # Получаем связанный объект PlanWork, если он существует
  def plan_work
    if defined?(PlanWork) && plan_work_id.present?
      PlanWork.find_by(id: plan_work_id)
    else
      nil
    end
  end

  # Проверяем существование связанного объекта PlanWork
  def plan_work_exists?
    defined?(PlanWork) && plan_work_id.present? && plan_work.present?
  end

  # Получаем распределение часов по месяцам для данной категории
  def hours_by_month
    result = Hash.new(0)

    work_plan_tasks.includes(:work_plan_task_distributions).each do |task|
      task.work_plan_task_distributions.each do |distribution|
        result[distribution.month] += distribution.hours
      end
    end

    result
  end
end