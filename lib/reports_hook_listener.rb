# plugins/report_registry/lib/reports_hook_listener.rb
class ReportsHookListener < Redmine::Hook::ViewListener
  # Подключение CSS и JavaScript
  def view_layouts_base_html_head(context = {})
    stylesheet_link_tag('report_registry', plugin: 'report_registry') +
      javascript_include_tag('report_registry', plugin: 'report_registry') +
      javascript_include_tag('report_menu', plugin: 'report_registry') +

      javascript_include_tag('modal_issues_handler', plugin: 'report_registry')

  end

  # def view_issues_show_description_bottom(context = {})
  #   issue = context[:issue]
  #   project = issue.project
  #
  #   # Проверяем, включен ли модуль report_registry
  #   return '' unless project.module_enabled?(:report_registry)
  #
  #   # Получаем отчеты для данной задачи
  #   reports = Report.joins(:issue_reports)
  #                   .where(issue_reports: { issue_id: issue.id })
  #                   .order(updated_at: :desc)
  #
  #   context[:controller].instance_variable_set("@reports", reports)
  #
  #   return context[:controller].send(:render_to_string, {
  #     partial: 'issues/report',
  #     locals: {
  #       reports: reports,
  #       issue: issue,
  #       project: project
  #     }
  #   })
  # end

  render_on :view_issues_show_details_bottom, :partial => 'hooks/report_registry/show_reports'
  render_on :view_issues_form_details_bottom, :partial => 'hooks/report_registry/form_reports'
end
