# lib/report_registry/version_patch.rb
module ReportRegistry
  module VersionPatch
    def self.included(base)
      base.class_eval do
        has_one :work_plan, dependent: :destroy

        # Метод проверки наличия активного плана работ
        def has_active_plan?
          work_plan.present? && work_plan.status != 'закрыт'
        end

        # Получение часов по контракту (для совместимости с westaco_versions)
        def contract_hours
          # Проверяем, определен ли метод contract_hours в плагине westaco_versions
          if respond_to?(:contract_hours_original)
            contract_hours_original
          else
            # Получаем ID кастомного поля из настроек
            custom_field_id = Setting.plugin_report_registry['contract_hours_field_id']

            if custom_field_id.present?
              # Ищем значение кастомного поля
              custom_value = custom_field_values.find { |v| v.custom_field_id.to_s == custom_field_id.to_s }
              return custom_value.value.to_f if custom_value && custom_value.value.present?
            end

            # Если нет плагина и кастомного поля, пробуем получить данные из плана работ
            if plan_works.present? && respond_to?(:plan_works)
              plan_works.sum(:hours).to_f
            else
              # Возвращаем 0, если ничего не нашли
              0
            end
          end
        end

        # Проверяем, есть ли план работ в версии (из westaco_versions)
        def plan_works
          if respond_to?(:original_plan_works)
            original_plan_works
          elsif defined?(PlanWork) && self.respond_to?(:plan_works_original)
            plan_works_original
          elsif defined?(PlanWork)
            # Если определен класс PlanWork, но нет метода план_works,
            # пробуем найти план работ по ID версии
            PlanWork.where(version_id: self.id)
          else
            # Возвращаем пустой массив, если ничего не нашли
            []
          end
        end

        # Подсчет общего количества часов в плане
        def total_planned_hours
          work_plan.present? ? work_plan.total_planned_hours : 0
        end

        # Подсчет общего количества отчетных часов
        def total_reported_hours
          reports.joins(:issue_reports).sum('issue_reports.reported_hours')
        end
      end
    end
  end
end

# Применяем патч к модели Version
unless Version.included_modules.include?(ReportRegistry::VersionPatch)
  Version.include ReportRegistry::VersionPatch
end