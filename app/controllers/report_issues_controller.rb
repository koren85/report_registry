class ReportIssuesController < ApplicationController
  before_action :find_project_or_report
  before_action :authorize

  # Получение списка задач отчета
  def index
    @issues = @report.issues
                     .includes(:status, :fixed_version, :parent, :project)
                     .order(sort_clause)

    render json: issues_to_json(@issues)
  end

  # Поиск задач для добавления в отчет
  def search
    scope = @project.issues
                    .includes(:status, :fixed_version)
                    .where.not(id: @report.issue_ids)

    if params[:q].present?
      scope = scope.where("CAST(id AS TEXT) LIKE :q OR LOWER(subject) LIKE :q",
                          q: "%#{params[:q].downcase}%")
    end

    @issues = scope.limit(50)
    render json: search_issues_to_json(@issues)
  end

  # Добавление задач в отчет
  def add_issues
    issue_ids = params[:issue_ids].map(&:to_i)
    issues = @project.issues.where(id: issue_ids)

    ActiveRecord::Base.transaction do
      issues.each do |issue|
        @report.issue_reports.create!(issue: issue)
      end
    end

    render json: { success: true }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Удаление задачи из отчета
  def remove_issue
    issue_report = @report.issue_reports.find_by!(issue_id: params[:issue_id])
    issue_report.destroy

    render json: { success: true }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def find_project_or_report
    @report = Report.find(params[:report_id]) if params[:report_id]
    @project = @report&.project || Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Not found' }, status: :not_found
  end

  def issues_to_json(issues)
    issues.map { |issue| issue_to_json(issue) }
  end

  def search_issues_to_json(issues)
    issues.map { |issue| search_issue_to_json(issue) }
  end

  def issue_to_json(issue)
    custom_field = Setting.plugin_report_registry['custom_field_id']
    custom_value = issue.custom_field_values.find { |v| v.custom_field_id.to_s == custom_field.to_s }&.value

    {
      id: issue.id,
      subject: issue.subject,
      status: issue.status.name,
      project: issue.project.name,
      version: issue.fixed_version&.name,
      start_date: issue.start_date,
      due_date: issue.due_date,
      parent_issue: issue.parent&.subject,
      custom_field_value: custom_value
    }
  end

  def search_issue_to_json(issue)
    {
      id: issue.id,
      subject: issue.subject,
      status: issue.status.name,
      version: issue.fixed_version&.name,
      start_date: issue.start_date,
      due_date: issue.due_date
    }
  end

  def sort_clause
    if params[:sort] && params[:direction]
      "#{params[:sort]} #{params[:direction]}"
    else
      'id DESC'
    end
  end
end