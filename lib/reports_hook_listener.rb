# plugins/report_registry/lib/reports_hook_listener.rb
class ReportsHookListener < Redmine::Hook::ViewListener
  # Подключение CSS и JavaScript
  def view_layouts_base_html_head(context = {})
    stylesheet_link_tag('report_registry', plugin: 'report_registry') +
      javascript_include_tag('report_registry', plugin: 'report_registry')
  end
  render_on :view_issues_show_details_bottom, :partial => 'hooks/report_registry/show_reports'
  render_on :view_issues_form_details_bottom, :partial => 'hooks/report_registry/form_reports'
end
