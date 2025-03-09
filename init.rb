# plugins/report_registry/init.rb
require File.expand_path('../app/helpers/reports_helper', __FILE__)
require File.expand_path('../lib/reports_hook_listener', __FILE__)
require File.expand_path('../lib/project_patch', __FILE__)
require File.expand_path('../app/controllers/registry_reports_controller', __FILE__)
require File.expand_path('../app/controllers/report_issues_controller', __FILE__)
require File.expand_path('../lib/report_registry/issue_query_patch', __FILE__)

# Подключаем новые файлы для работы с планами
#require File.expand_path('../lib/report_registry/report_patch', __FILE__)
#require File.expand_path('../lib/report_registry/version_patch', __FILE__)

Redmine::Plugin.register :report_registry do
  name 'Report Registry Plugin'
  author 'Your Name'
  description 'Управление реестром отчетов и планирование работ'
  version '0.2.0'
  requires_redmine version_or_higher: '4.0'



  # Добавление пункта в главное меню (top_menu)
  menu :top_menu, :global_reports,
       { controller: 'registry_reports', action: 'index' },
       caption: 'Все отчёты',
       if: Proc.new { |proj| User.current.admin? || User.current.allowed_to_globally?(:view_reports_global) },
       html: { class: 'icon icon-reports' }

  # Добавление пункта в главное меню для глобальных планов работ
  menu :top_menu, :global_work_plans,
       { controller: 'work_plans', action: 'global_index' },
       caption: 'Все планы работ',
       if: Proc.new { |proj| User.current.admin? || User.current.allowed_to_globally?(:view_work_plans_global) },
       html: { class: 'icon icon-plan' },
       after: :global_reports

  # Регистрация модуля в настройках проекта
  project_module :report_registry do
    # Разрешения для просмотра отчетов
    permission :view_reports, {
      registry_reports: [:index, :show, :search],
      report_issues: [:index, :modal_issues, :search, :select_search]
    }, read: true

    # Разрешения для управления отчетами
    permission :manage_reports, {
      registry_reports: [:new, :create, :edit, :update, :destroy, :approve],
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
      registry_reports: [:approve]
    }

    # Глобальные разрешения для просмотра отчетов
    permission :view_reports_global, {
      registry_reports: [:index, :show, :search],
      report_issues: [:index, :modal_issues, :search, :select_search]
    }, global: true

    # Глобальные разрешения для управления отчетами
    permission :manage_reports_global, {
      registry_reports: [:new, :create, :edit, :update, :destroy],
      report_issues: [:modal_issues, :add_issues, :search, :select_search, :remove_issue, :add_issue, :remove_issues]
    }, global: true

    # Разрешение для удаления задач из отчета
    permission :remove_issues, {
      report_issues: [:remove_issues, :remove_issue]
    }

    # Добавляем разрешения для работы с планами
    permission :view_work_plans, {
      work_plans: [:index, :show],
      work_plan_categories: [:show],
      work_plan_tasks: [:show]
    }, read: true

    permission :manage_work_plans, {
      work_plans: [:new, :create, :edit, :update, :destroy, :approve, :close, :create_report, :create_categories],
      work_plan_categories: [:new, :create, :edit, :update, :destroy],
      work_plan_tasks: [:new, :create, :edit, :update, :destroy, :distribute_hours, :search_issues]
    }

    # Глобальные разрешения для работы с планами
    permission :view_work_plans_global, {
      work_plans: [:index, :show],
      work_plan_categories: [:show],
      work_plan_tasks: [:show]
    }, global: true

    permission :manage_work_plans_global, {
      work_plans: [:new, :create, :edit, :update, :destroy, :approve, :close, :create_report, :create_categories],
      work_plan_categories: [:new, :create, :edit, :update, :destroy],
      work_plan_tasks: [:new, :create, :edit, :update, :destroy, :distribute_hours, :search_issues]
    }, global: true
  end

  # Добавление пункта меню в проекты с включенным модулем
  menu :project_menu, :report_registry,
       { controller: 'registry_reports', action: 'index' },
       caption: 'Отчеты',
       param: :project_id,
       if: -> (project) { project.module_enabled?(:report_registry) }

  # Добавляем пункт меню для планов работ
  menu :project_menu, :work_plans,
       { controller: 'work_plans', action: 'index' },
       caption: 'Планы работ',
       param: :project_id,
       if: -> (project) { project.module_enabled?(:report_registry) },
       after: :report_registry


  # Добавляем настройки плагина
  settings(
    default: {
      'custom_field_id' => nil,
      'custom_field_name' => 'Кастомное поле',
      'hours_source' => 'estimated_hours',
      'contract_hours_field_id' => nil # Добавляем поле для хранения ID кастомного поля с часами по контракту
    },
    partial: 'settings/report_registry_settings'
  )


end
# Добавляем загрузку хуков
Rails.application.config.to_prepare do
  require_dependency 'reports_hook_listener'
  require_dependency 'issue' # Убедитесь, что модель Issue загружена перед патчем
  Issue.include ReportRegistry::IssuePatch

  # Подключаем патчи для работы с планами
  require_dependency 'report' # Добавьте явную загрузку модели Report перед патчем
  require_dependency 'version' # Добавьте явную загрузку модели Version перед патчем
  require_dependency 'report_registry/report_patch'
  require_dependency 'report_registry/version_patch'

  # Подключаем патчи для работы с планами
  Report.include ReportRegistry::ReportPatch
  Version.include ReportRegistry::VersionPatch


end