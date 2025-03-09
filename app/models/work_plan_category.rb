# app/models/work_plan_category.rb
class WorkPlanCategory < ActiveRecord::Base
  belongs_to :work_plan
  has_many :work_plan_tasks, dependent: :destroy

  validates :category_name, presence: true
  validates :planned_hours, numericality: { greater_than_or_equal_to: 0 }
  validates :plan_work_id, uniqueness: { scope: :work_plan_id, message: :error_category_already_exists }, allow_nil: true

  after_save :update_work_plan_hours
  after_destroy :update_work_plan_hours

  # Обновляем сумму запланированных часов на основе задач в категории
  def update_planned_hours
    # Сначала проверяем, есть ли в категории задачи
    if work_plan_tasks.loaded?
      # Если задачи уже загружены, используем их для подсчета
      self.planned_hours = work_plan_tasks.sum(&:total_hours)
    else
      # Иначе делаем запрос к базе данных
      self.planned_hours = work_plan_tasks.sum(:total_hours)
    end

    # Если план работ связан с PlanWork и у нас нет задач, берем часы из него
    if plan_work_exists? && work_plan_tasks.count == 0
      plan_work_hours = plan_work.respond_to?(:hours) ? plan_work.hours : 0
      self.planned_hours = plan_work_hours if plan_work_hours > 0
    end

    self.planned_hours
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

  private

  # Обновляем часы в родительском плане
  def update_work_plan_hours
    if work_plan
      # Обновляем общие часы плана
      work_plan.touch # Вызываем обновление временной метки
    end
  end
end