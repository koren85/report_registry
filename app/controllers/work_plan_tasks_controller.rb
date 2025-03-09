# app/controllers/work_plan_tasks_controller.rb
class WorkPlanTasksController < ApplicationController
  before_action :find_project_by_project_id
  before_action :find_work_plan
  before_action :find_category
  before_action :find_task, only: [:show, :edit, :update, :destroy, :distribute_hours]
  before_action :authorize

  accept_api_auth :index, :show, :create, :update, :destroy

  # Список задач в категории
  def index
    @tasks = @category.work_plan_tasks.includes(:issue, :work_plan_task_distributions)

    respond_to do |format|
      format.html { redirect_to project_work_plan_work_plan_category_path(@project, @work_plan, @category) }
      format.api
      format.js
    end
  end

  # Отображение задачи
  def show
    @distributions = @task.work_plan_task_distributions.order(:month)

    respond_to do |format|
      format.html
      format.api
      format.js
    end
  end

  # Новая задача
  def new
    @task = @category.work_plan_tasks.build
    @available_issues = available_issues

    respond_to do |format|
      format.html
      format.js
    end
  end

  # Создание задачи
  def create
    @task = @category.work_plan_tasks.build(task_params)

    respond_to do |format|
      if @task.save
        # Если есть параметры распределения часов, создаем их
        if params[:hours_by_month].present?
          @task.distribute_hours(params[:hours_by_month])
        end

        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to project_work_plan_work_plan_category_path(@project, @work_plan, @category)
        }
        format.js
        format.api { render action: 'show', status: :created }
      else
        @available_issues = available_issues
        format.html { render action: 'new' }
        format.js { render action: 'new' }
        format.api { render_validation_errors(@task) }
      end
    end
  end

  # Редактирование задачи
  def edit
    @distributions = @task.work_plan_task_distributions.order(:month)
    @hours_by_month = @task.hours_by_month

    respond_to do |format|
      format.html
      format.js
    end
  end

  # Обновление задачи
  def update
    respond_to do |format|
      if @task.update(task_params)
        # Если есть параметры распределения часов, обновляем их
        if params[:hours_by_month].present?
          @task.distribute_hours(params[:hours_by_month])
        end

        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to project_work_plan_work_plan_category_work_plan_task_path(@project, @work_plan, @category, @task)
        }
        format.js
        format.api { render_api_ok }
      else
        @distributions = @task.work_plan_task_distributions.order(:month)
        @hours_by_month = @task.hours_by_month

        format.html { render action: 'edit' }
        format.js { render action: 'edit' }
        format.api { render_validation_errors(@task) }
      end
    end
  end

  # Удаление задачи
  def destroy
    if @task.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_unable_delete_task)
    end

    respond_to do |format|
      format.html { redirect_to project_work_plan_work_plan_category_path(@project, @work_plan, @category) }
      format.js
      format.api { render_api_ok }
    end
  end

  # Распределение часов по месяцам
  def distribute_hours
    if params[:hours_by_month].present?
      @task.distribute_hours(params[:hours_by_month])
      flash[:notice] = l(:notice_hours_distributed)
    else
      flash[:error] = l(:error_no_hours_specified)
    end

    respond_to do |format|
      format.html { redirect_to project_work_plan_work_plan_category_work_plan_task_path(@project, @work_plan, @category, @task) }
      format.js
      format.api { render_api_ok }
    end
  end

  # Поиск задач для добавления в план
  def search_issues
    @query = params[:q] || ''
    scope = available_issues

    if @query.present?
      scope = scope.where("CAST(#{Issue.table_name}.id AS TEXT) ILIKE :q OR LOWER(#{Issue.table_name}.subject) ILIKE :q", q: "%#{@query.downcase}%")
    end

    @issues = scope.limit(50)

    respond_to do |format|
      format.html { render partial: 'search_results', layout: false }
      format.js
      format.api { render template: 'issues/index' }
      format.json { render json: @issues.map { |i| { id: i.id, text: "##{i.id} - #{i.subject}" } } }
    end
  end

  private

  def find_work_plan
    @work_plan = WorkPlan.find(params[:work_plan_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_category
    @category = @work_plan.work_plan_categories.find(params[:work_plan_category_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_task
    @task = @category.work_plan_tasks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def task_params
    params.require(:work_plan_task).permit(:issue_id, :total_hours, :accounting_month,
                                           :report_inclusion_month, :comments, :result)
  end

  # Получаем доступные задачи для добавления в план
  def available_issues
    # Получаем ID всех задач, которые уже есть в плане
    used_issue_ids = @work_plan.work_plan_tasks.pluck(:issue_id)

    # Получаем доступные задачи проекта и подпроектов
    scope = Issue.where(project_id: @project.self_and_descendants.pluck(:id))

    # Если у плана есть версия, фильтруем задачи по версии
    if @work_plan.version_id.present?
      scope = scope.where(fixed_version_id: @work_plan.version_id)
    end

    # Исключаем задачи, которые уже есть в плане
    scope = scope.where.not(id: used_issue_ids) if used_issue_ids.any?

    scope.includes(:status, :project)
  end

  # Преобразуем параметры распределения часов по месяцам
  def parse_hours_by_month
    hours_by_month = {}

    if params[:hours_by_month].present?
      params[:hours_by_month].each do |month, hours|
        month_num = month.to_i
        next if month_num < 1 || month_num > 12

        hours_value = hours.to_f
        hours_by_month[month_num] = hours_value if hours_value > 0
      end
    end

    hours_by_month
  end
end