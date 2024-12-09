# plugins/report_registry/init.rb
require File.expand_path('../app/helpers/reports_helper', __FILE__)
require File.expand_path('../lib/reports_hook_listener', __FILE__)
require File.expand_path('../lib/project_patch', __FILE__)

require_dependency 'reports_hook_listener'

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
    permission :view_reports, { reports: [:index, :show] }
    permission :manage_reports, { reports: [:new, :create, :edit, :update, :destroy, :approve] }
    permission :view_reports_global, { reports: [:index] }, global: true
    permission :manage_reports_global, { reports: [:new, :create] }, global: true
  end

  # Добавление пункта меню в проекты с включенным модулем
  menu :project_menu, :report_registry,
       { controller: 'reports', action: 'index' },
       caption: 'Отчеты',
       param: :project_id,
       if: Proc.new { |project| project.module_enabled?(:report_registry) }

end
