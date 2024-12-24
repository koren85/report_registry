class ReportsController < ApplicationController
  helper :sort
  include SortHelper
  helper :queries
  include QueriesHelper
  before_action :require_login
  before_action :find_report, only: [:edit, :update, :destroy, :approve, :show]
  before_action :find_project
  before_action :ensure_project_module_enabled, if: -> { @project.present? }

  # Сначала проверяем админа
  before_action :skip_authorization_for_admin, if: -> { User.current.admin? }

  # Потом остальные проверки для не-админов
  before_action :authorize_global, only: [:index], if: -> { !User.current.admin? && @project.nil? }
  before_action :authorize, if: -> { !User.current.admin? && @project.present? }

  def index
    retrieve_query
    @query.project = @project if @project

    scope = @query.base_scope

    if params[:project_id]
      scope = scope.where(project_id: @project.id)
    end

    # Обновляем инициализацию сортировки
    sort_init(@query.sort_criteria.empty? ? [["#{Report.table_name}.id", 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    # Применяем фильтры если они есть
    if @query.valid? && @query.statement.present?
      scope = scope.where(@query.statement)
    end

    # Применяем сортировку, проверяя наличие sort_clause
    if sort_clause.present?
      scope = scope.order(sort_clause)
    else
      scope = scope.order("#{Report.table_name}.id DESC")
    end

    @item_count = scope.count
    @item_pages = Paginator.new @item_count, per_page_option, params['page']
    @items = scope.limit(@item_pages.per_page).offset(@item_pages.offset)

    respond_to do |format|
      format.html
    end
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

  def load_project_versions
    project = Project.find(params[:project_id])
    versions = project.versions.where.not(status: 'closed').map { |v| { id: v.id, name: v.name } }

    render json: versions
  rescue ActiveRecord::RecordNotFound
    render json: []
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
      load_project_and_versions
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
      format.html # добавляем явный рендеринг html формата
      format.api
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def retrieve_query
    if params[:set_filter] || session[:reports_query].nil?
      @query = ReportQuery.new(:name => "_")
      @query.build_from_params(params)
      session[:reports_query] = {:filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      @query = ReportQuery.new(:name => "_",
                               :filters => session[:reports_query][:filters] || params[:fields] || {},
                               :group_by => session[:reports_query][:group_by],
                               :column_names => session[:reports_query][:column_names])
    end
  end

  def report_params_with_unique_issues
    params_copy = report_params.dup
    if params_copy[:issue_ids].present?
      # Убираем дубликаты из массива issue_ids
      params_copy[:issue_ids] = params_copy[:issue_ids].uniq
    end
    params_copy
  end

  def report_params
    params.require(:report).permit(:name, :period, :start_date, :end_date, :status,
                                   :total_hours, :contract_number, :project_id,
                                   :version_id, issue_ids: [])
  end

  def find_report
    @report = Report.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = if params[:project_id]
                 Project.find(params[:project_id])
               elsif @report&.project
                 @report.project
               end
  end

  def load_versions
    @versions = @project&.versions&.where.not(status: 'closed') || []
    @projects_with_module = Project.active.has_module(:report_registry) unless @project
  end

  def ensure_project_module_enabled
    return true if User.current.admin? # Администратор игнорирует проверку
    unless @project&.module_enabled?(:report_registry)
      render_403
    end
  end



  def authorize_global
    # Проверка глобального права
    allowed = User.current.allowed_to_globally?(:manage_reports_global)
    render_403 unless allowed
  end

  def load_project_and_versions
    @projects_with_module = Project.active.has_module(:report_registry)
    if @report.project
      @versions = @report.project.versions.where.not(status: 'closed')
    else
      @versions = []
    end
  end

  def authorize_unless_admin
    return true if User.current.admin? # Администраторы получают полный доступ
    authorize
  end

  def skip_authorization_for_admin
    true # Просто пропускаем все проверки для админа
  end
end