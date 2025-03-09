# app/models/work_plan_task.rb
class WorkPlanTask < ActiveRecord::Base
  belongs_to :work_plan_category
  belongs_to :issue

  has_many :work_plan_task_distributions, dependent: :destroy
  has_many :report_plan_links, dependent: :destroy
  has_many :reports, through: :report_plan_links

  validates :total_hours, numericality: { greater_than_or_equal_to: 0 }
  validates :accounting_month, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }, allow_nil: true
  validates :report_inclusion_month, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }, allow_nil: true
  validates :issue_id, uniqueness: { scope: :work_plan_category_id, message: :error_issue_already_exists_in_category }

  after_save :update_category_hours
  after_destroy :update_category_hours

  # Получаем процент выполнения задачи по отчетам
  def completion_percentage
    return 0 if total_hours.zero?

    reported = report_plan_links.sum(:reported_hours)
    (reported / total_hours * 100).round(2)
  end

  # Проверяем, завершена ли задача
  def completed?
    completion_percentage >= 100
  end

  # Оставшиеся часы
  def remaining_hours
    reported = report_plan_links.sum(:reported_hours)
    [total_hours - reported, 0].max
  end

  # Распределение часов по месяцам
  def distribute_hours(hours_by_month)
    # Удаляем существующие распределения
    work_plan_task_distributions.destroy_all

    total = 0

    # Создаем новые распределения
    hours_by_month.each do |month, hours|
      next if hours.to_f <= 0

      work_plan_task_distributions.create!(
        month: month,
        hours: hours
      )

      total += hours.to_f
    end

    # Обновляем общее количество часов
    update_column(:total_hours, total)

    # Обновляем часы категории
    update_category_hours
  end

  # Получаем часы по месяцам как хеш
  def hours_by_month
    result = Hash.new(0)

    work_plan_task_distributions.each do |distribution|
      result[distribution.month] = distribution.hours
    end

    result
  end

  # Получаем название проекта задачи
  def project_name
    issue.project.name
  end

  # Получаем связанный план работ
  def work_plan
    work_plan_category.work_plan
  end

  private

  # Обновляем плановые часы для категории
  def update_category_hours
    work_plan_category.update_planned_hours
    work_plan_category.save
  end
end