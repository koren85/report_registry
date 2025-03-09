# app/controllers/work_plan_categories_controller.rb
class WorkPlanCategoriesController < ApplicationController
  before_action :find_project_by_project_id
  before_action :find_work_plan
  before_action :find_category, only: [:show, :edit, :update, :destroy]
  before_action :authorize
  before_action :find_available_plan_works, only: [:new, :edit, :create, :update]

  # Показ категории с задачами
  def show
    @tasks = @category.work_plan_tasks.includes(:issue, :work_plan_task_distributions)

    respond_to do |format|
      format.html
      format.api
      format.js
    end
  end

  # Новая категория
  def new
    @category = @work_plan.work_plan_categories.build

    respond_to do |format|
      format.html
      format.js
    end
  end

  # Создание категории
  def create
    @category = @work_plan.work_plan_categories.build(category_params)

    respond_to do |format|
      if @category.save
        # Обновляем planned_hours после создания
        @category.update_planned_hours
        @category.save

        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to project_work_plan_path(@project, @work_plan)
        }
        format.js
        format.api { render action: 'show', status: :created }
      else
        format.html { render action: 'new' }
        format.js { render action: 'new' }
        format.api { render_validation_errors(@category) }
      end
    end
  end

  # Редактирование категории
  def edit
    respond_to do |format|
      format.html
      format.js
    end
  end

  # Обновление категории
  def update
    respond_to do |format|
      if @category.update(category_params)
        # Обновляем planned_hours после обновления
        @category.update_planned_hours
        @category.save

        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to project_work_plan_path(@project, @work_plan)
        }
        format.js
        format.api { render_api_ok }
      else
        format.html { render action: 'edit' }
        format.js { render action: 'edit' }
        format.api { render_validation_errors(@category) }
      end
    end
  end

  # Удаление категории
  def destroy
    if @category.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_unable_delete_category)
    end

    respond_to do |format|
      format.html { redirect_to project_work_plan_path(@project, @work_plan) }
      format.js
      format.api { render_api_ok }
    end
  end

  private

  def find_work_plan
    @work_plan = WorkPlan.find(params[:work_plan_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_category
    @category = @work_plan.work_plan_categories.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_available_plan_works
    @available_plan_works = []

    # Проверяем доступность PlanWork из плагина westaco_versions
    if defined?(PlanWork)
      # Получаем уже использованные plan_work_id
      used_plan_work_ids = @work_plan.work_plan_categories.pluck(:plan_work_id).compact

      if @work_plan.version.respond_to?(:plan_works)
        # Если метод plan_works определен
        @available_plan_works = @work_plan.version.plan_works
                                    .where.not(id: used_plan_work_ids)
                                    .map { |pw| [pw.name, pw.id] }
      elsif PlanWork.table_exists?
        # Иначе ищем PlanWork по ID версии
        @available_plan_works = PlanWork.where(version_id: @work_plan.version_id)
                                     .where.not(id: used_plan_work_ids)
                                     .map { |pw| [pw.name, pw.id] }
      end
    end
  rescue => e
    logger.error "Error finding plan works: #{e.message}"
    @available_plan_works = []
  end

  def category_params
    params.require(:work_plan_category).permit(:category_name, :plan_work_id)
  end
end