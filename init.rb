# plugins/report_registry/init.rb
require File.expand_path('../app/helpers/reports_helper', __FILE__)
require File.expand_path('../lib/reports_hook_listener', __FILE__)
require File.expand_path('../lib/project_patch', __FILE__)
require File.expand_path('../app/controllers/reports_controller', __FILE__)
require File.expand_path('../app/controllers/report_issues_controller', __FILE__)
require File.expand_path('../lib/report_registry/issue_query_patch', __FILE__)

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
       { controller: 'reports', action: 'index' },
       caption: 'Все отчёты',
       if: Proc.new { |proj| User.current.admin? || User.current.allowed_to_globally?(:view_reports_global) },
       html: { class: 'icon icon-reports' }

  # Регистрация модуля в настройках проекта
  project_module :report_registry do
    # Разрешения для просмотра отчетов
    permission :view_reports, {
      reports: [:index, :show, :search],
      report_issues: [:index, :modal_issues, :search, :select_search]
    }, read: true

    # Разрешения для управления отчетами
    permission :manage_reports, {
      reports: [:new, :create, :edit, :update, :destroy, :approve],
      report_issues: [:modal_issues, :add_issues, :search, :select_search, :remove_issue, :add_issue, :remove_issues]
    }

    # права изменения имени задачи в отчете
    permission :edit_report_issue_titles,
                    { report_issues: [:update_title] },
                    read: true,
                    require: :member

    # права изменения часов в отчете
    permission :edit_report_hours,
               { report_issues: [:update_hours] },
               read: true,
               require: :member

    # Разрешение для утверждения отчетов
    permission :approve_reports, {
      reports: [:approve]
    }

    # Глобальные разрешения для просмотра отчетов
    permission :view_reports_global, {
      reports: [:index, :show, :search],
      report_issues: [:index, :modal_issues, :search, :select_search]
    }, global: true

    # Глобальные разрешения для управления отчетами
    permission :manage_reports_global, {
      reports: [:new, :create, :edit, :update, :destroy],
      report_issues: [:modal_issues, :add_issues, :search, :select_search, :remove_issue, :add_issue, :remove_issues]
    }, global: true

    # Разрешение для удаления задач из отчета
    permission :remove_issues, {
      report_issues: [:remove_issues, :remove_issue]
    }
  end

  # Добавление пункта меню в проекты с включенным модулем
  menu :project_menu, :report_registry,
       { controller: 'reports', action: 'index' },
       caption: 'Отчеты',
       param: :project_id,
       if: -> (project) { project.module_enabled?(:report_registry) }


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