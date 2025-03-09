# app/controllers/work_plans_controller.rb
class WorkPlansController < ApplicationController
  before_action :find_project_by_project_id
  before_action :find_work_plan, only: [:show, :edit, :update, :destroy, :approve, :close]
  before_action :find_version, only: [:new, :create]
  before_action :authorize

  helper :sort
  include SortHelper

  # Список планов работ
  def index
    @versions = @project.versions.where.not(status: 'closed').includes(:work_plan)

    sort_init 'created_on', 'desc'
    sort_update(
      'id' => "#{WorkPlan.table_name}.id",
      'name' => "#{WorkPlan.table_name}.name",
      'year' => "#{WorkPlan.table_name}.year",
      'version' => "#{Version.table_name}.name",
      'status' => "#{WorkPlan.table_name}.status",
      'created_on' => "#{WorkPlan.table_name}.created_at"
    )

    @work_plans = WorkPlan.joins(:version)
                          .where(versions: { project_id: @project.id })
                          .order(sort_clause)

    respond_to do |format|
      format.html
      format.api
    end
  end

  # Глобальный список планов работ
  def global_index
    @project = nil # Явно указываем, что не находимся в контексте проекта

    # Проверяем права для глобального доступа
    unless User.current.admin? || User.current.allowed_to_globally?(:view_work_plans_global)
      render_403
      return
    end

    sort_init 'created_on', 'desc'
    sort_update(
      'id' => "#{WorkPlan.table_name}.id",
      'name' => "#{WorkPlan.table_name}.name",
      'year' => "#{WorkPlan.table_name}.year",
      'project' => "#{Project.table_name}.name",
      'version' => "#{Version.table_name}.name",
      'status' => "#{WorkPlan.table_name}.status",
      'created_on' => "#{WorkPlan.table_name}.created_at"
    )

    scope = WorkPlan.joins(version: :project)
                    .includes(version: :project)

    # Применяем фильтр по видимым проектам
    if User.current.admin?
      # Администраторы видят все планы
    else
      # Обычные пользователи видят только планы из доступных им проектов
      visible_project_ids = Project.allowed_to(User.current, :view_work_plans).pluck(:id)
      scope = scope.where(versions: { project_id: visible_project_ids })
    end

    # Применяем сортировку
    @work_plans = scope.order(sort_clause)

    # Поддержка пагинации
    @limit = per_page_option
    @work_plan_count = scope.count
    @work_plan_pages = Paginator.new @work_plan_count, @limit, params['page']
    @offset = @work_plan_pages.offset
    @work_plans = @work_plans.limit(@limit).offset(@offset)

    respond_to do |format|
      format.html
      format.api
    end
  end

  # Отображение плана работ
  def show
    # Если параметр project_id отсутствует, это глобальный доступ
    if params[:project_id].blank?
      @project = @work_plan.version.project

      # Проверка прав доступа в глобальном контексте
      unless User.current.admin? || User.current.allowed_to?(:view_work_plans, @project) ||
        User.current.allowed_to_globally?(:view_work_plans_global)
        render_403
        return
      end

      # Установка флага глобального контекста
      @global_access = true
    else
      # Установка флага проектного контекста
      @global_access = false
    end

    @categories = @work_plan.work_plan_categories.includes(:work_plan_tasks)

    respond_to do |format|
      format.html
      format.api
      format.js
    end
  end

  # Новый план работ
  def new
    # Проверяем, что у версии еще нет плана работ
    if @version.work_plan.present?
      flash[:error] = l(:error_version_already_has_plan)
      redirect_to project_work_plans_path(@project)
      return
    end

    @work_plan = WorkPlan.new(version_id: @version.id, year: Date.today.year)

    # Если есть интеграция с плагином westaco_versions, создаем категории на основе PlanWork
    create_categories_from_plan_works if plan_works_available?

    respond_to do |format|
      format.html
      format.js
    end
  end

  # Создание плана работ
  def create
    @work_plan = WorkPlan.new(work_plan_params)
    @work_plan.created_by = User.current.id
    @work_plan.updated_by = User.current.id

    respond_to do |format|
      if @work_plan.save
        # Создаем категории из PlanWorks, если они доступны
        create_categories_from_plan_works if plan_works_available? && params[:create_from_plan_works]

        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to project_work_plan_path(@project, @work_plan)
        }
        format.api { render action: 'show', status: :created, location: work_plan_url(@work_plan) }
      else
        format.html { render action: 'new' }
        format.api { render_validation_errors(@work_plan) }
      end
    end
  end

  # Редактирование плана работ
  def edit
    @categories = @work_plan.work_plan_categories.includes(:work_plan_tasks)
  end

  # Обновление плана работ
  def update
    respond_to do |format|
      @work_plan.updated_by = User.current.id

      if @work_plan.update(work_plan_params)
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to project_work_plan_path(@project, @work_plan)
        }
        format.api { render_api_ok }
      else
        format.html { render action: 'edit' }
        format.api { render_validation_errors(@work_plan) }
      end
    end
  end

  # Удаление плана работ
  def destroy
    if @work_plan.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_unable_delete_work_plan)
    end

    respond_to do |format|
      format.html { redirect_to project_work_plans_path(@project) }
      format.api { render_api_ok }
    end
  end

  # Утверждение плана работ
  def approve
    @work_plan.status = 'утвержден'
    @work_plan.updated_by = User.current.id

    respond_to do |format|
      if @work_plan.save
        flash[:notice] = l(:notice_work_plan_approved)
        format.html { redirect_to project_work_plan_path(@project, @work_plan) }
        format.api { render_api_ok }
      else
        flash[:error] = l(:error_work_plan_approval_failed)
        format.html { redirect_to project_work_plan_path(@project, @work_plan) }
        format.api { render_validation_errors(@work_plan) }
      end
    end
  end

  # Закрытие плана работ
  def close
    @work_plan.status = 'закрыт'
    @work_plan.updated_by = User.current.id

    respond_to do |format|
      if @work_plan.save
        flash[:notice] = l(:notice_work_plan_closed)
        format.html { redirect_to project_work_plan_path(@project, @work_plan) }
        format.api { render_api_ok }
      else
        flash[:error] = l(:error_work_plan_closing_failed)
        format.html { redirect_to project_work_plan_path(@project, @work_plan) }
        format.api { render_validation_errors(@work_plan) }
      end
    end
  end

  # Создание отчета на основе плана
  def create_report
    @work_plan = WorkPlan.find(params[:id])
    month = params[:month].to_i
    year = params[:year].to_i

    # Проверяем корректность месяца и года
    if month < 1 || month > 12 || year < 2000 || year > 2100
      flash[:error] = l(:error_invalid_month_year)
      redirect_to project_work_plan_path(@project, @work_plan)
      return
    end

    # Создаем отчет на основе плана
    @report = Report.create_from_plan(@work_plan, month, year, {
      contract_number: params[:contract_number],
      status: params[:status] || 'черновик'
    })

    if @report.persisted?
      flash[:notice] = l(:notice_report_created_from_plan)
      redirect_to edit_project_registry_report_path(@project, @report)
    else
      flash[:error] = l(:error_report_creation_failed)
      redirect_to project_work_plan_path(@project, @work_plan)
    end
  end

  private

  def find_work_plan
    @work_plan = WorkPlan.find(params[:id])
    @version = @work_plan.version
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_version
    @version = Version.find(params[:version_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def work_plan_params
    params.require(:work_plan).permit(:name, :year, :status, :notes, :version_id)
  end

  # Проверяем доступность PlanWork из плагина westaco_versions
  def plan_works_available?
    defined?(PlanWork) && @version.respond_to?(:plan_works)
  end

  # Создаем категории на основе PlanWork из плагина westaco_versions
  def create_categories_from_plan_works
    return unless plan_works_available? && @version.respond_to?(:plan_works)

    @version.plan_works.each do |plan_work|
      @work_plan.work_plan_categories.build(
        plan_work_id: plan_work.id,
        category_name: plan_work.name,
        planned_hours: 0
      )
    end
  end
end