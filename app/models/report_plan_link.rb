# app/models/report_plan_link.rb
class ReportPlanLink < ActiveRecord::Base
  belongs_to :report
  belongs_to :work_plan_task

  validates :reported_hours, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, inclusion: { in: %w[запланировано включено перенесено] }
  validates :work_plan_task_id, uniqueness: { scope: :report_id, message: :error_task_already_linked }

  # Получаем задачу из связанной задачи плана
  def issue
    work_plan_task.issue
  end

  # Получаем связанный план работ
  def work_plan
    work_plan_task.work_plan_category.work_plan
  end

  # Создать соответствующий IssueReport при создании связи
  after_create :create_issue_report

  private

  # Создаем запись IssueReport, если она не существует
  def create_issue_report
    unless report.issue_reports.exists?(issue_id: issue.id)
      issue_report = report.issue_reports.new(
        issue: issue,
        report_title: issue.subject,
        reported_hours: reported_hours
      )
      issue_report.save
    end
  end
end