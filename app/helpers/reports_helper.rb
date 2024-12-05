# plugins/report_registry/app/helpers/reports_helper.rb
module ReportsHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    direction = (column == params[:sort] && params[:direction] == 'asc') ? 'desc' : 'asc'
    link_to title, { sort: column, direction: direction }
  end
end
