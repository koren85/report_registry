class ReportsController < ApplicationController
  helper :sort
  include SortHelper
  helper :queries
  include QueriesHelper

  before_action :require_login
  before_action :find_optional_project
  before_action :find_report, only: [:edit, :update, :destroy, :approve, :show]
  before_action :ensure_project_module_enabled, if: -> { @project.present? }

  # Сначала проверяем админа
  before_action :skip_authorization_for_admin, if: -> { User.current.admin? }

  # Потом остальные проверки для не-админов
  before_action :authorize_global, only: [:index, :new, :create], if: -> { !User.current.admin? && @project.nil? }
  before_action :authorize, if: -> { !User.current.admin? && @project.present? }

  def find_optional_project
    return true if params[:project_id].blank? # Если project_id не указан, просто пропускаем

    # Поиск проекта по identifier или id
    @project = Project.find_by(identifier: params[:project_id]) ||
               Project.find_by(id: params[:project_id])

    # Проверяем, что проект существует и доступен
    if params[:project_id].present? && @project.nil?
      render_404
      return false
    end

    # Проверяем, что модуль включен
    if @project && !@project.module_enabled?(:report_registry)
      render_403
      return false
    end

    true
  end

  def index
    retrieve_query
    @query.project = @project if @project

    scope = Report.joins(:project)
                 .includes(:project)
                 .references(:project)

  if @project
    scope = scope.where(project_id: @project.id)
  elsif @query.statement.present?
    # Находим ID проекта по identifier и подставляем в условие
    if @query.filters["project_id"].present?
      project = Project.find_by(identifier: @query.filters["project_id"][:values].first)
      scope = project ? scope.where(project_id: project.id) : scope.none
    end
  end

  sort_init(@query.sort_criteria.empty? ? [["#{Report.table_name}.id", 'desc']] : @query.sort_criteria)
  sort_update(@query.sortable_columns)

  scope = scope.reorder(sort_clause) if sort_clause.present?

  @item_count = scope.count
  @item_pages = Paginator.new @item_count, per_page_option, params['page']
  @items = scope.limit(@item_pages.per_page).offset(@item_pages.offset).to_a

    respond_to do |format|
      format.html
      format.api
    end
  rescue StandardError => e
    logger.error "Error in index action: #{e.message}\n#{e.backtrace.join("\n")}"
    render_error message: :error_internal_error
  end

  def new
    if @project
      @report = @project.reports.new
      load_versions
      authorize
    else
      @report = Report.new
      @projects_with_module = Project.active.has_module(:report_registry)
      authorize_global
    end
  end

  def create
    @report = if @project
                @project.reports.new(report_params)
              else
                Report.new(report_params)
              end

    @report.created_by = User.current.id
    @report.updated_by = User.current.id
    @report.updated_at = Time.current

    if @report.save
      flash[:notice] = l(:notice_successful_create)
      if params[:save_and_continue]
        redirect_to edit_report_path(@report)
      else
        redirect_to(@project ? project_reports_path(@project) : reports_path)
      end
    else
      load_versions
      render :new
    end
  end

  def edit
    @from_global = params[:from_global]
    @issues = if @project
                @project.issues
              elsif @report.project
                @report.project.issues
              else
                []
              end
    @versions = @report.project&.versions&.where.not(status: 'closed') || []
    @projects_with_module = Project.active.has_module(:report_registry) unless @project
  end

  def update
    @report.assign_attributes(report_params_with_unique_issues)
    @report.updated_by = User.current.id
    @report.updated_at = Time.current

    if @report.save
      flash[:notice] = l(:notice_successful_update)
      if params[:save_and_continue]
        redirect_to edit_report_path(@report)
      else
        if params[:from_global] == 'true'
          redirect_to reports_path
        else
          redirect_to project_reports_path(@report.project)
        end
      end
    else
      load_versions
      @from_global = params[:from_global]
      render :edit
    end
  end

  def destroy
    @report.destroy
    redirect_to reports_path, notice: 'Отчет успешно удален'
  end

  def approve
    @report.update(status: 'утвержден', updated_by: User.current.id)
    redirect_to reports_path, notice: 'Отчет успешно утвержден'
  end

  def show
    @report = Report.find(params[:id])
    @tasks = @report.issues

    respond_to do |format|
      format.html
      format.api
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def load_project_versions
    project = Project.find(params[:project_id])
    versions = project.versions.where.not(status: 'closed').map { |v| { id: v.id, name: v.name } }
    render json: versions
  rescue ActiveRecord::RecordNotFound
    render json: []
  end

  private

  def render_error(options={})
    options = options.merge(status: 500)
    render_error_status(options)
  end

  def render_error_status(options={})
    options = {status: 500, layout: true}.merge(options)
    @project = nil
    render template: 'common/error', status: options[:status], layout: options[:layout]
  end

  def ensure_project_module_enabled
    return true if User.current.admin? || @project.nil?
    unless @project&.module_enabled?(:report_registry)
      render_403
      return false
    end
    true
  end

  def retrieve_query
    @query = ReportQuery.new(name: "_")

    if params[:set_filter] || session[:reports_query].nil?
      # Преобразуем project_id в число, если он присутствует
      if params[:project_id].present?
        project = Project.find_by(identifier: params[:project_id])
        params[:project_id] = project.id if project
      end

      @query.build_from_params(params)
      session[:reports_query] = {
        filters: @query.filters,
        group_by: @query.group_by,
        column_names: @query.column_names
      }
    else
      @query.filters = session[:reports_query][:filters] || params[:fields] || {}
      @query.group_by = session[:reports_query][:group_by]
      @query.column_names = session[:reports_query][:column_names]
    end

    @query
  end

  def authorize_global
    allowed = User.current.admin? ||
              User.current.allowed_to_globally?(:view_reports_global) ||
              User.current.allowed_to_globally?(:manage_reports_global)
    unless allowed
      render_403
      return false
    end
    true
  end

  def skip_authorization_for_admin
    true if User.current.admin?
  end

  def find_report
    @report = Report.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def report_params_with_unique_issues
    params_copy = report_params.dup
    if params_copy[:issue_ids].present?
      params_copy[:issue_ids] = params_copy[:issue_ids].uniq
    end
    params_copy
  end

  def report_params
    params.require(:report).permit(
      :name, :period, :start_date, :end_date, :status,
      :total_hours, :contract_number, :project_id,
      :version_id, issue_ids: []
    )
  end

  def load_versions
    @versions = @project&.versions&.where.not(status: 'closed') || []
    @projects_with_module = Project.active.has_module(:report_registry) unless @project
  end
end