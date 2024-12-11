class IssuesController < ApplicationController
  before_action :find_project
  before_action :authorize, except: [:index]

  helper :sort
  include SortHelper

  def index
    @issues = @project.issues.open
    render json: @issues.select(:id, :subject)
  end

  # Метод для получения данных таблицы с сортировкой
  def table_data
    sort_init 'id', 'asc'
    sort_update %w(id subject status_id fixed_version_id start_date due_date parent_id)

    @issues = @project.issues
                     .includes(:status, :fixed_version, :parent)
                     .order(sort_clause)

    # Получаем ID кастомного поля "подзадача" из настроек плагина
    subtask_field_id = Setting.plugin_report_registry['subtask_field_id']

    issues_data = @issues.map do |issue|
      {
        id: issue.id,
        subject: issue.subject,
        status: issue.status.try(:name),
        version: issue.fixed_version.try(:name),
        start_date: issue.start_date,
        due_date: issue.due_date,
        parent_issue: issue.parent.try(:subject),
        subtask: subtask_field_id ? issue.custom_field_value(subtask_field_id) : nil
      }
    end

    render json: issues_data
  end

  # Получение списка доступных статусов для новой задачи
  def statuses
    statuses = IssueStatus.sorted.map { |s| { id: s.id, name: s.name } }
    render json: statuses
  end

  # Создание новой задачи
  def create
    @issue = Issue.new(issue_params)
    @issue.project = @project
    @issue.author = User.current
    @issue.tracker ||= @project.trackers.first

    if @issue.save
      render json: {
        success: true,
        issue: {
          id: @issue.id,
          subject: @issue.subject,
          status: @issue.status.try(:name),
          version: @issue.fixed_version.try(:name),
          start_date: @issue.start_date,
          due_date: @issue.due_date,
          parent_issue: @issue.parent.try(:subject),
          subtask: @issue.custom_field_value(Setting.plugin_report_registry['subtask_field_id'])
        }
      }
    else
      render json: { success: false, errors: @issue.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def issue_params
    params.require(:issue).permit(
      :subject,
      :status_id,
      :fixed_version_id,
      :start_date,
      :due_date,
      :parent_id,
      custom_field_values: [Setting.plugin_report_registry['subtask_field_id']]
    )
  end
end
