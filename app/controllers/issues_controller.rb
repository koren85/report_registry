class IssuesController < ApplicationController
  before_action :find_project
  before_action :authorize

  def index_for_report
    @issues = @project.issues
                      .includes(:status, :fixed_version, :parent, :project)
                      .order(sort_clause)

    render json: issues_to_json(@issues)
  end

  def create_for_report
    @issue = @project.issues.build(issue_params)
    @issue.author = User.current

    if @issue.save
      render json: issue_to_json(@issue)
    else
      render json: { errors: @issue.errors }, status: :unprocessable_entity
    end
  end

  def statuses
    @statuses = IssueStatus.all
    render json: @statuses.map { |s| { id: s.id, name: s.name } }
  end

  def assignable_users
    @users = @project.assignable_users
    render json: @users.map { |u| { id: u.id, name: u.name } }
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Project not found' }, status: :not_found
  end

  def issue_params
    params.require(:issue).permit(
      :subject,
      :status_id,
      :fixed_version_id,
      :assigned_to_id,
      :start_date,
      :due_date,
      :custom_field_values
    )
  end

  def issues_to_json(issues)
    issues.map { |issue| issue_to_json(issue) }
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

  def sort_clause
    if params[:sort] && params[:direction]
      "#{params[:sort]} #{params[:direction]}"
    else
      'id DESC'
    end
  end
end