# plugins/report_registry/app/controllers/reports_controller.rb
class ReportsController < ApplicationController
  before_action :require_login

  def index
    sort_column = params[:sort] || 'created_at'
    sort_direction = params[:direction] || 'desc'

    # Обработка сортировки по связям
    if sort_column == 'created_by'
      sort_column = '(SELECT lastname || \' \' || firstname  FROM users WHERE users.id = reports.created_by)'
    elsif sort_column == 'updated_by'
      sort_column = '(SELECT lastname || \' \' ||  firstname FROM users WHERE users.id = reports.updated_by)'
    end

    @reports = Report.order("#{sort_column} #{sort_direction}")
    @periods = Report.distinct.pluck(:period)
    @statuses = %w[черновик в_работе сформирован утвержден]
    @users = User.all
  end
end
