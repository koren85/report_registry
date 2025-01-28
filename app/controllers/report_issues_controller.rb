# app/controllers/report_issues_controller.rb
class ReportIssuesController < ApplicationController
  before_action :find_report_or_init
  before_action :find_project_from_report

  before_action :find_project_by_params
  before_action :find_issue , only: [:remove_issue, :add_issue]
  before_action :find_report , only: [:modal_issues, :index, :search, :add_issues, :remove_issue, :remove_issues, :add_issue, :select_search]
  before_action :authorize # Оставляем стандартный authorize, так как права уже определены в init.rb

  def modal_issues
    @issues = issues_scope
                .where.not(id: @report.issue_ids)
                .includes(:status, :fixed_version, :project)
                .order(created_on: :desc)
                .limit(100)

    respond_to do |format|
      format.html { render partial: 'modal_issues', layout: false }
      format.js
    end
  rescue => e
    logger.error "Error in modal_issues: #{e.message}\n#{e.backtrace.join("\n")}"
    respond_to do |format|
      format.html { render_404 }
      format.js { render js: "alert('#{j l(:error_loading_modal)}');" }
    end
  end

  def select_search
    Rails.logger.info "=== Select Search Debug ==="
    Rails.logger.info "Current user: #{User.current.inspect}"
    Rails.logger.info "Project: #{@project.inspect}"
    Rails.logger.info "Report: #{@report.inspect}"
    Rails.logger.info "Permissions: #{User.current.roles_for_project(@project).map(&:permissions).flatten}"

    @issues = issues_scope
                .includes(:status, :fixed_version, :project)
                .where.not(id: @report.issue_ids)

    if params[:q].present?
      @issues = @issues.where(
        "CAST(#{Issue.table_name}.id AS TEXT) ILIKE :q OR LOWER(#{Issue.table_name}.subject) ILIKE :q",
        q: "%#{params[:q].downcase}%"
      )
    end

    @issues = apply_sort_to_scope(@issues).limit(100)

    respond_to do |format|
      format.html { render partial: 'search_results', layout: false }
      format.js { render partial: 'search_results', layout: false }
      format.json {
        render json: @issues.map { |issue| {
          id: issue.id,
          text: "##{issue.id} - #{issue.subject}",
          subject: issue.subject,
          project: issue.project.name
        }}
      }
    end
  rescue => e
    logger.error "Select search error: #{e.message}\n#{e.backtrace.join("\n")}"
    respond_to do |format|
      format.html { render_error l(:error_search_failed) }
      format.js { render js: "alert('#{j l(:error_search_failed)}');" }
      format.json { render json: { error: l(:error_search_failed) }, status: :unprocessable_entity }
    end
  rescue => e
    Rails.logger.error "Select search error: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: e.message }, status: :forbidden
  end
  def search
    Rails.logger.info "Search initiated..."
    Rails.logger.info "Current user: #{User.current.inspect}"
    Rails.logger.info "Session: #{session.inspect}"
    Rails.logger.info "Request format: #{request.format}"

    @issues = issues_scope
              .includes(:status, :fixed_version, :project)
              .where.not(id: @report.issue_ids)

    if params[:q].present?
      @issues = @issues.where(
        "CAST(issues.id AS TEXT) LIKE :q OR LOWER(issues.subject) LIKE :q",
        q: "%#{params[:q].downcase}%"
      )
    end

    @issues = apply_sort_to_scope(@issues).limit(50)

    respond_to do |format|
      format.html { render partial: 'search_results', layout: false }
      format.js { render partial: 'search_results', layout: false }
    end
  rescue => e
    logger.error "Search error: #{e.message}\n#{e.backtrace.join("\n")}"
    respond_to do |format|
      format.html { render_error l(:error_search_failed) }
      format.js { render js: "alert('#{j l(:error_search_failed)}');" }
    end
  end

  def add_issues
    if params[:issue_ids].present?
      # Массовое добавление
      new_issue_ids = params[:issue_ids].uniq - @report.issue_ids.map(&:to_s)
      @issues = Issue.where(id: new_issue_ids)
      @report.issues << @issues

      # Обновление отчёта
      @report.updated_by = User.current.id
      @report.updated_at = Time.current
      @report.save
    elsif params[:issue_id].present?
      # Одиночное добавление
      @issue = Issue.find(params[:issue_id])
      unless @report.issues.include?(@issue)
        @report.issues << @issue
        @report.updated_by = User.current.id
        @report.updated_at = Time.current
        @report.save
      end
    end

    @report.reload

    respond_to do |format|
      format.html { redirect_to edit_report_path(@report) }
      format.js
    end
  rescue => e
    Rails.logger.error "Error adding issues: #{e.message}\n#{e.backtrace.join("\n")}"
    respond_to do |format|
      format.html do
        flash[:error] = l(:error_adding_issues)
        redirect_to edit_report_path(@report)
      end
      format.js { render js: "alert('#{l(:error_adding_issues)}');", status: :unprocessable_entity }
    end
  end

  def remove_issue
    if @report.issue_reports.where(issue_id: @issue.id).destroy_all
      @report.touch
      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js { render js: "alert('#{l(:error_unable_delete)}');" }
      end
    end
  end

  def remove_issues
    @issue_ids = params[:issue_ids]

    if @issue_ids.present?
      begin
        @report.issue_reports.where(issue_id: @issue_ids).destroy_all
        @report.touch

        respond_to do |format|
          format.js
        end
      rescue => e
        Rails.logger.error "Error in remove_issues: #{e.message}\n#{e.backtrace.join("\n")}"
        respond_to do |format|
          format.js { render js: "alert('#{j l(:error_unable_delete)}');" }
        end
      end
    else
      respond_to do |format|
        format.js { render js: "alert('#{j l(:notice_no_issues_selected)}');" }
      end
    end
  end

  private

  def issues_scope
    if @report.new_record?
      Issue.all
    else
      scope = Issue.where(project_id: @project.self_and_descendants.pluck(:id))
      scope = scope.where(fixed_version_id: @report.version_id) if @report.version_id.present?
      scope
    end
  end

  def find_report_or_init
    report_id = params[:report_id]
    @report = if report_id == '0'
                Report.new(project_id: params[:project_id])
              else
                Report.find(params[:report_id])
              end
  end

  def find_project_from_report
    @project = if params[:project_id]
                 Project.find(params[:project_id])
               elsif @report&.project_id
                 @report.project
               end
  end

  def check_user_logged_in
    unless User.current.is_a?(User) && User.current.active?
      render_403
      return false
    end
  end

  def authorize
    Rails.logger.info "=== Authorization Debug ==="
    Rails.logger.info "Action: #{action_name}"
    Rails.logger.info "Controller: #{controller_name}"
    Rails.logger.info "Current user permissions: #{User.current.roles_for_project(@project).map(&:permissions).flatten}"

    unless User.current.logged?
      respond_to do |format|
        format.html { redirect_to signin_path }
        format.json { head :unauthorized }
        format.api  { head :unauthorized }
      end
      return false
    end
    super
  rescue => e
    Rails.logger.error "Authorization error: #{e.message}"
    respond_to do |format|
      format.json { head :forbidden }
    end
  end

  # def find_authentication_token
  #   token = params[:key] || request.headers['X-Redmine-API-Key']
  #   token || nil
  # end

  # def check_xhr_request
  #   unless request.xhr?
  #     respond_to do |format|
  #       format.html { render_404 }
  #       format.json { render json: { error: 'XHR request required' }, status: :forbidden }
  #     end
  #   end
  # end

  def apply_sort_to_scope(scope)
    return scope.order('id DESC') unless params[:sort].present?

    column = case params[:sort].to_s
             when 'id' then 'issues.id'
             when 'subject' then 'issues.subject'
             when 'project' then 'projects.name'
             when 'status' then 'issue_statuses.position'
             when 'version' then 'versions.effective_date'
             when 'start_date' then 'issues.start_date'
             when 'due_date' then 'issues.due_date'
             else 'issues.created_on'
             end

    direction = params[:direction] == 'desc' ? 'desc' : 'asc'
    scope.order("#{column} #{direction} NULLS LAST")
  end

  def sort_clause
    if params[:sort].present?
      column = case params[:sort].to_s
               when 'id'         then 'issues.id'
               when 'subject'    then 'issues.subject'
               when 'project'    then 'projects.name'
               when 'status'     then 'issue_statuses.position'
               when 'version'    then 'versions.effective_date'
               when 'start_date' then 'issues.start_date'
               when 'due_date'   then 'issues.due_date'
               else 'issues.created_on'
               end
      direction = params[:direction] == 'desc' ? 'desc' : 'asc'
      "#{column} #{direction} NULLS LAST"
    else
      'issues.created_on DESC'
    end
  end

  def find_project_by_params
    @project = if params[:project_id]
                 Project.find(params[:project_id])
               elsif params[:report_id]
                 report = Report.find(params[:report_id])
                 report.project
               end

    unless @project
      Rails.logger.error "Project not found for params: #{params.inspect}"
      render_404
    end
  end

  def available_project_issues
    # Получаем ID всех подпроектов включая текущий проект
    project_ids = @project.self_and_descendants.pluck(:id)
    Issue.where(project_id: project_ids)
  end

  def find_report
    @report = Report.find(params[:report_id])
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Report not found: #{e.message}"
    render_404
  end

  # def find_project
  #   @project = @report.project
  #   if @project.nil?
  #     render_404
  #   end
  # end

  def find_issue
    @issue = @project.issues.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project_by_report
    @report = Report.find_by(id: params[:report_id])
    @project = @report&.project || Project.find_by(id: params[:project_id])
    unless @project
      render_404
    end
  end

  # def search_issue_to_json(issue)
  #   {
  #     id: issue.id,
  #     subject: issue.subject,
  #     status: issue.status.name,
  #     project: issue.project.name,
  #     version: issue.fixed_version&.name,
  #     start_date: issue.start_date,
  #     due_date: issue.due_date
  #   }
  # end

  # def search_issues_to_json(issues)
  #   issues.map { |issue| search_issue_to_json(issue) }
  # end

  # def issue_to_json(issue)
  #   {
  #     id: issue.id,
  #     subject: issue.subject,
  #     project: issue.project.name,
  #     status: issue.status.name,
  #     version: issue.fixed_version&.name,
  #     start_date: issue.start_date&.strftime('%Y-%m-%d'),
  #     due_date: issue.due_date&.strftime('%Y-%m-%d')
  #   }
  # end
end