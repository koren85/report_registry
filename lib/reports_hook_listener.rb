# plugins/report_registry/lib/reports_hook_listener.rb
class ReportsHookListener < Redmine::Hook::ViewListener
  # Подключение CSS и JavaScript
  def view_layouts_base_html_head(context = {})
    stylesheet_link_tag('report_registry', plugin: 'report_registry') +
      javascript_include_tag('report_registry', plugin: 'report_registry') +
      javascript_include_tag('report_menu', plugin: 'report_registry') +
      javascript_include_tag('modal_issues_handler', plugin: 'report_registry')+
      stylesheet_link_tag('work_plans', plugin: 'report_registry') +
      javascript_include_tag('work_plans', plugin: 'report_registry')

  end

  # Добавляем вкладку "Планы работ" на страницу проекта
  def view_projects_show_right(context = {})
    project = context[:project]

    # Проверяем, включен ли модуль report_registry и есть ли у пользователя права
    if project.module_enabled?(:report_registry) && User.current.allowed_to?(:view_work_plans, project)
      # Рендерим вкладку и содержимое для планов работ
      tab_content = context[:controller].send(:render_to_string, {
        partial: 'work_plans/project_tab',
        locals: { project: project }
      })

      return tab_content
    else
      return ''
    end
  end

  # Добавляем пункт в меню вкладок проекта
  def view_projects_tabs(context = {})
    project = context[:project]

    # Проверяем, включен ли модуль report_registry и есть ли у пользователя права
    if project.module_enabled?(:report_registry) && User.current.allowed_to?(:view_work_plans, project)
      return [
        {
          name: 'work_plans',
          url: { controller: 'work_plans', action: 'index', project_id: project },
          label: :label_work_plans
        }
      ]
    else
      return []
    end
  end

  render_on :view_issues_show_details_bottom, :partial => 'hooks/report_registry/show_reports'
  #render_on :view_issues_form_details_bottom, :partial => 'hooks/report_registry/form_reports'
end
