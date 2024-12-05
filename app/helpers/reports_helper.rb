module ReportsHelper
  def sort_init(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    @sort_default = options[:default] || args.shift
    @sort_direction_default = options[:direction] || 'asc'

    if params[:sort].present?
      @sort_criteria = params[:sort]
      @sort_direction = params[:direction]
    else
      @sort_criteria = @sort_default
      @sort_direction = @sort_direction_default
    end
  end

  def sort_update(columns)
    @sort_criteria = params[:sort] if params[:sort].present?
    @sort_direction = params[:direction] if params[:direction].present?

    @sort_criteria = @sort_default unless columns.include?(@sort_criteria)
  end

  def sort_clause
    "#{@sort_criteria} #{@sort_direction}"
  end

  def sortable(column, label)
    css_classes = ['sort']
    if column == @sort_criteria
      css_classes << @sort_direction
    end

    link_to_if column,
               label,
               params.permit!.to_h.merge(sort: column,
                                         direction: (column == @sort_criteria && @sort_direction == 'asc' ? 'desc' : 'asc')),
               class: css_classes.join(' ')
  end
end