class ReportsController < ApplicationController
  helper :sort
  include SortHelper
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
    sort_init 'created_at', 'desc'
    sort_update %w(id name period status created_at updated_at created_by updated_by project_id)

    scope = @project ? @project.reports : Report.includes(:project)
    scope = scope.order(sort_clause)

    @limit = per_page_option
    @item_count = scope.count
    @item_pages = Paginator.new @item_count, @limit, params['page']
    @items = scope.offset(@item_pages.offset).limit(@item_pages.per_page)

    @periods = Report.distinct.pluck(:period)
    @statuses = %w[черновик в_работе сформирован утвержден]
    @users = User.all
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

    if @report.save
      redirect_to(@project ? project_reports_path(@project) : reports_path, notice: 'Отчёт успешно создан')
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
    @report.assign_attributes(report_params)
    @report.updated_by = User.current.id  # Добавляем текущего пользователя как обновившего

    if @report.save
      flash[:notice] = l(:notice_successful_update)
      if params[:from_global] == 'true'
        redirect_to reports_path
      else
        redirect_to project_reports_path(@report.project)
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
  end

  private

  def report_params
    params.require(:report).permit(:name, :period, :start_date, :end_date, :status, :total_hours,
                                   :contract_number, :project_id, :version_id, issue_ids: [])
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