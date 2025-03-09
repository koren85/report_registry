# lib/report_registry/report_patch.rb
module ReportRegistry
  module ReportPatch
    def self.included(base)
      base.class_eval do
        has_many :report_plan_links, dependent: :destroy
        has_many :work_plan_tasks, through: :report_plan_links

        # Создание отчета на основе плана работ
        def self.create_from_plan(work_plan, month, year, options = {})
          # Находим проект по версии плана
          project = work_plan.version.project

          # Создаем новый отчет
          report = Report.new({
                                name: "#{project.name} - #{work_plan.version.name} - #{I18n.t('date.month_names')[month]} #{year}",
                                period: 'месячный',
                                project_id: project.id,
                                version_id: work_plan.version_id,
                                selected_month: month,
                                selected_year: year,
                                status: 'черновик',
                                created_by: User.current.id,
                                updated_by: User.current.id
                              }.merge(options))

          # Устанавливаем даты периода
          report.start_date = Date.new(year, month, 1)
          report.end_date = report.start_date.end_of_month

          # Если отчет сохранен успешно, добавляем задачи
          if report.save
            # Находим задачи для месяца учета
            accounting_tasks = work_plan.work_plan_tasks
                                        .where(accounting_month: month)

            # Находим задачи для месяца включения в отчет
            inclusion_tasks = work_plan.work_plan_tasks
                                       .where(report_inclusion_month: month)

            # Объединяем оба набора задач
            all_tasks = (accounting_tasks + inclusion_tasks).uniq

            # Создаем связи с задачами плана
            all_tasks.each do |task|
              # Находим распределение для текущего месяца
              distribution = task.work_plan_task_distributions.find_by(month: month)

              # Если есть распределение на этот месяц, используем эти часы
              hours = distribution ? distribution.hours : nil

              # Создаем связь между отчетом и задачей плана
              report.report_plan_links.create(
                work_plan_task: task,
                reported_hours: hours,
                status: 'включено'
              )
            end
          end

          report
        end

        # Метод для получения связанных планов работ
        def related_work_plans
          work_plan_ids = work_plan_tasks.joins(work_plan_category: :work_plan)
                                         .select('work_plan_categories.work_plan_id')
                                         .distinct
                                         .pluck('work_plan_categories.work_plan_id')

          WorkPlan.where(id: work_plan_ids)
        end
      end
    end
  end
end

# Применяем патч к модели Report
# unless Report.included_modules.include?(ReportRegistry::ReportPatch)
#   Report.include ReportRegistry::ReportPatch
# end