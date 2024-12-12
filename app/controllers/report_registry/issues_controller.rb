module ReportRegistry
  class IssuesController < ApplicationController
    before_action :find_project
    before_action :authorize_global, only: [:index], if: -> { @project.nil? }
    before_action :authorize, if: -> { @project.present? }

    helper :sort
    include SortHelper

    def index
      @issues = @project.issues.open
      render json: @issues.select(:id, :subject)
    end

    def table_data
      return unless User.current.allowed_to?(:view_report_issues, @project)

      sort_init 'id', 'asc'
      sort_update %w(id subject status_id fixed_version_id start_date due_date parent_id)

      @issues = @project.issues
                        .includes(:status, :fixed_version, :parent)

      # Фильтруем по версии, если она указана в параметрах
      if params[:version_id].present?
        @issues = @issues.where(fixed_version_id: params[:version_id])
      end

      # Добавляем сортировку
      @issues = @issues.order(sort_clause)

      issues_data = @issues.map do |issue|
        {
          id: issue.id,
          subject: issue.subject,
          status: issue.status.try(:name),
          version: issue.fixed_version.try(:name),
          start_date: issue.start_date,
          due_date: issue.due_date,
          parent_issue: issue.parent.try(:subject),
          subtask: issue.custom_field_value(Setting.plugin_report_registry['subtask_field_id'])
        }
      end

      render json: issues_data
    end

    def available_assignees
      return unless User.current.allowed_to?(:manage_report_issues, @project)

      role_id = Setting.plugin_report_registry['assignee_role_id']
      users = @project.users_by_role[Role.find(role_id)].to_a
      render json: users.map { |u| { id: u.id, name: u.name } }
    end

    def create
      return unless User.current.allowed_to?(:manage_report_issues, @project)

      @issue = Issue.new(issue_params)
      @issue.project = @project
      @issue.author = User.current
      @issue.tracker_id = Setting.plugin_report_registry['default_tracker_id']
      @issue.status_id = Setting.plugin_report_registry['default_status_id']

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
            assigned_to: @issue.assigned_to.try(:name)
          }
        }
      else
        render json: { success: false, errors: @issue.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    private

    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def issue_params
      params.require(:issue).permit(:subject, :assigned_to_id, :fixed_version_id,
                                  :start_date, :due_date)
    end
  end
end