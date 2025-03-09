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
          if respond_to?(:contract_hours_original)
            contract_hours_original
          else
            # Здесь можно добавить альтернативную логику, если contract_hours не определены
            # Например, сумму оценок задач в версии
            custom_field_id = Setting.plugin_report_registry['contract_hours_field_id']

            if custom_field_id.present?
              custom_value = custom_values.find_by(custom_field_id: custom_field_id)
              return custom_value.value.to_f if custom_value
            end

            0
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