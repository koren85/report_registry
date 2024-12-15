# app/controllers/report_issues_controller.rb
class ReportIssuesController < ApplicationController
  before_action :find_report
  before_action :find_project
  before_action :authorize

  def modal_issues
    @issues = @project.issues
                      .where.not(id: @report.issue_ids)
                      .includes(:status, :fixed_version)
                      .limit(100)

    respond_to do |format|
      format.html { render partial: 'modal_issues' }
      format.js
    end
  rescue => e
    Rails.logger.error "Error in modal_issues: #{e.message}\n#{e.backtrace.join("\n")}"
    respond_to do |format|
      format.html { render_404 }
      format.js { render js: "alert('#{l(:error_loading_modal)}');" }
    end
  end

  def index
    @issues = @report.issues
                     .includes(:status, :fixed_version, :parent, :project)
                     .order(sort_clause)

    render json: issues_to_json(@issues)
  end

  def search
    scope = @project.issues
                    .includes(:status, :fixed_version)
                    .where.not(id: @report.issue_ids)

    if params[:q].present?
      scope = scope.where("CAST(issues.id AS TEXT) LIKE :q OR LOWER(issues.subject) LIKE :q",
                          q: "%#{params[:q].downcase}%")
    end

    @issues = scope.limit(50)
    render json: search_issues_to_json(@issues)
  end


  def add_issues
    if params[:issue_ids].present?
      @issues = Issue.where(id: params[:issue_ids])
      @report.issues << @issues
    end

    respond_to do |format|
      format.html { redirect_to edit_report_path(@report) }
      format.js   # будет использовать add_issues.js.erb
    end
  end

  def remove_issue
    @issue_report = @report.issue_reports.find_by!(issue_id: params[:issue_id])

    if @issue_report.destroy
      respond_to do |format|
        format.html { redirect_to edit_report_path(@report) }
        format.js   # Будет использовать remove_issue.js.erb
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = l(:error_removing_issue)
          redirect_to edit_report_path(@report)
        }
        format.js { render js: "alert('#{l(:error_removing_issue)}');" }
        format.json { render json: { error: l(:error_removing_issue) }, status: :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    respond_to do |format|
      format.html {
        flash[:error] = l(:error_issue_not_found)
        redirect_to edit_report_path(@report)
      }
      format.js { render js: "alert('#{l(:error_issue_not_found)}');" }
      format.json { render json: { error: l(:error_issue_not_found) }, status: :not_found }
    end
  end

  private


  def find_report
    @report = Report.find(params[:report_id])
    @project = @report.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = @report.project
    if @project.nil?
      render_404
    end
  end

  def find_project_by_report
    @report = Report.find_by(id: params[:report_id])
    @project = @report&.project || Project.find_by(id: params[:project_id])
    unless @project
      render_404
    end
  end

  def issues_to_json(issues)
    issues.map { |issue| issue_to_json(issue) }
  end

  def search_issues_to_json(issues)
    issues.map { |issue| search_issue_to_json(issue) }
  end

  def issue_to_json(issue)
    custom_field = Setting.plugin_report_registry['custom_field_id']
    custom_value = issue.custom_field_values
                        .find { |v| v.custom_field_id.to_s == custom_field.to_s }&.value

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
    if params[:sort].present? && params[:direction].present?
      sanitized_sort = params[:sort].gsub(/[^a-zA-Z0-9_]/, '')
      sanitized_direction = params[:direction] == 'desc' ? 'desc' : 'asc'
      "#{sanitized_sort} #{sanitized_direction}"
    else
      'id DESC'
    end
  end
end