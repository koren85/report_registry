# plugins/report_registry/init.rb
Redmine::Plugin.register :report_registry do
  name 'Report Registry Plugin'
  author 'Your Name'
  description 'Управление реестром отчетов'
  version '0.1.0'
  requires_redmine version_or_higher: '4.0'

  # Добавление пункта в главное меню (top_menu)
  menu :top_menu,
       :report_registry,
       { controller: 'reports', action: 'index' },
       caption: :menu_reports, # используем символ для перевода
       after: :projects,       # указываем позицию после "Проекты"
       if: Proc.new { User.current.logged? }, # только для авторизованных пользователей
       html: { class: 'icon icon-reports' }   # класс для иконки
end
