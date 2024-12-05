class ReportsController < ApplicationController
  helper :sort
  include SortHelper
  before_action :require_login
  before_action :find_report, only: [:edit, :update, :destroy, :approve]
  before_action :ensure_project_module_enabled, only: [:new, :create]

  before_action :find_project, only: [:index, :new, :create, :edit, :update, :destroy]
  before_action :authorize_global, only: [:index], if: -> { @project.nil? }
  before_action :authorize, except: [:index]


  def index
    @items = if @project
               @project.reports.order(created_at: :desc)
             else
               Report.includes(:project).order(created_at: :desc)
             end
  end


  def new
    @report = if @project
                @project.reports.new
              else
                Report.new
              end
    load_versions
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
    load_project_and_versions
  end

  def update
    if @report.update(report_params)
      redirect_to project_reports_path(@report.project), notice: 'Отчет успешно обновлен'
    else
      load_project_and_versions
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


  def find_project
    if params[:project_id]
      @project = Project.find_by(id: params[:project_id])
      render_404 unless @project
    end
  end

  def load_versions
    @versions = @project&.versions&.where.not(status: 'closed') || []
    @projects_with_module = Project.active.has_module(:report_registry) unless @project
  end

def ensure_project_module_enabled
  unless @project&.module_enabled?(:report_registry)
    render_403
  end
end

  def authorize_global
    # Проверяем глобальное право просмотра отчётов
    allowed = User.current.allowed_to_globally?(:view_reports)
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

end