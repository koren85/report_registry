# plugins/report_registry/app/helpers/reports_helper.rb
module ReportsHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == params[:sort]) ? params[:direction] : nil
    direction = (column == params[:sort] && params[:direction] == 'asc') ? 'desc' : 'asc'
    link_to title, { sort: column, direction: direction }, class: css_class
  end
end
