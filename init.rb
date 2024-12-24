# plugins/report_registry/init.rb
require File.expand_path('../app/helpers/reports_helper', __FILE__)
require File.expand_path('../lib/reports_hook_listener', __FILE__)
require File.expand_path('../lib/project_patch', __FILE__)
# require 'report_registry/hooks'
#
# Rails.application.config.to_prepare do
# require_dependency 'reports_hook_listener'
#
# end

Redmine::Plugin.register :report_registry do
  name 'Report Registry Plugin'
  author 'Your Name'
  description 'Управление реестром отчетов'
  version '0.1.0'
  requires_redmine version_or_higher: '4.0'



  # Добавление пункта в главное меню (top_menu)
  menu :top_menu, :global_reports,
       { controller: 'reports', action: 'index' ,  project_id: nil},
       caption: 'Все отчёты',
       if: Proc.new { User.current.allowed_to_globally?(:view_reports_global) },
       html: { class: 'icon icon-reports' }

  # Регистрация модуля в настройках проекта
  project_module :report_registry do
    permission :view_reports, { reports: [:index, :show],
                                report_issues: [:index, :modal_issues] }
    permission :manage_reports, { reports: [:new, :create, :edit, :update, :destroy, :approve],
                                  report_issues: [:modal_issues, :add_issues, :search, :remove_issue] }
    permission :approve_reports, { reports: [:approve] }
    permission :view_reports_global, { reports: [:index] }, global: true
    permission :manage_reports_global, { reports: [:new, :create] }, global: true
    permission :remove_issues, { report_issues: [:remove_issues] }, require: :member

  end

  # Добавление пункта меню в проекты с включенным модулем
  menu :project_menu, :report_registry,
       { controller: 'reports', action: 'index' },
       caption: 'Отчеты',
       param: :project_id,
       if: Proc.new { |project| project.module_enabled?(:report_registry) }


  # Добавляем настройки плагина
  settings(
    default: {
      'custom_field_id' => nil,
      'custom_field_name' => 'Кастомное поле'
    },
    partial: 'settings/report_registry_settings'
  )


end
# Добавляем загрузку хуков
Rails.application.config.to_prepare do
  require_dependency 'reports_hook_listener'
  Issue.include ReportRegistry::IssuePatch
end