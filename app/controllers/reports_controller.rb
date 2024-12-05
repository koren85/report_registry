class ReportsController < ApplicationController
  helper :sort
  include SortHelper
  before_action :require_login

  def index
    # Инициализация сортировки
    sort_init 'created_at', 'desc'
    sort_update %w(id name period status created_at updated_at total_hours contract_number created_by updated_by)

    # Базовый запрос с сортировкой
    scope = Report.order(sort_clause)

    # Пагинация
    @limit = per_page_option
    @item_count = scope.count
    @item_pages = Paginator.new(@item_count, @limit, params['page'])
    @items = scope.limit(@limit).offset(@item_pages.offset)

    # Дополнительные данные
    @periods = Report.distinct.pluck(:period)
    @statuses = %w[черновик в_работе сформирован утвержден]
    @users = User.all
  end
end