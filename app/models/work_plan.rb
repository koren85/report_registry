# app/models/work_plan.rb
class WorkPlan < ActiveRecord::Base
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by'
  belongs_to :updater, class_name: 'User', foreign_key: 'updated_by', optional: true
  belongs_to :version

  has_many :work_plan_categories, dependent: :destroy
  has_many :work_plan_tasks, through: :work_plan_categories

  validates :name, presence: true
  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2000, less_than: 2100 }
  validates :status, presence: true, inclusion: { in: %w[черновик утвержден закрыт] }
  validates :version_id, presence: true, uniqueness: { message: :error_version_already_has_plan }

  before_save :set_updater

  # Общая сумма запланированных часов по категориям
  def total_planned_hours
    work_plan_categories.sum(:planned_hours)
  end

  # Часы по контракту из версии
  def contract_hours
    version.try(:contract_hours) || 0
  end

  # Разница между контрактными часами и запланированными
  def hours_difference
    contract_hours - total_planned_hours
  end

  # Проверка на перерасход часов
  def hours_overrun?
    hours_difference < 0
  end

  # Получение распределения часов по месяцам
  def hours_by_month
    result = Hash.new(0)

    work_plan_tasks.includes(:work_plan_task_distributions).each do |task|
      task.work_plan_task_distributions.each do |distribution|
        result[distribution.month] += distribution.hours
      end
    end

    result
  end

  # Проверка прав доступа
  def visible?(user=User.current)
    return true if user.admin?

    project = version.project
    if project
      user.allowed_to?(:view_work_plans, project) ||
        user.allowed_to?(:manage_work_plans, project)
    else
      user.allowed_to_globally?(:manage_work_plans_global)
    end
  end

  def editable?(user=User.current)
    return true if user.admin?
    return false if status == 'закрыт'

    project = version.project
    if project
      user.allowed_to?(:manage_work_plans, project)
    else
      user.allowed_to_globally?(:manage_work_plans_global)
    end
  end

  private

  def set_updater
    if changed?
      self.updated_by = User.current.id
      self.updated_at = Time.current
    end
  end
end