class ReportQuery < Query
  self.queried_class = Report

  self.available_columns = [
    QueryColumn.new(:id, sortable: 'id', caption: 'ID'),
    QueryColumn.new(:name, sortable: 'name', caption: :field_name),
    QueryColumn.new(:project, sortable: "#{Project.table_name}.name", groupable: true),
    QueryColumn.new(:period, sortable: 'period', caption: :field_period),
    QueryColumn.new(:start_date, sortable: 'start_date', caption: :field_start_date),
    QueryColumn.new(:end_date, sortable: 'end_date', caption: :field_end_date),
    QueryColumn.new(:status, sortable: 'status', caption: :field_status),
    QueryColumn.new(:created_at, sortable: 'created_at', caption: :field_created_on),
    QueryColumn.new(:updated_at, sortable: 'updated_at', caption: :field_updated_on),
    QueryColumn.new(:created_by, sortable: "#{User.table_name}.lastname", caption: :field_created_by),
    QueryColumn.new(:contract_number, sortable: 'contract_number', caption: :field_contract_number),
    QueryColumn.new(:version, sortable: "#{Version.table_name}.name", groupable: true)
  ]

  def base_scope
    Report.includes(:project, :creator).
      references(:project, :creator)
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {}
    add_available_filter "name", type: :string
    add_available_filter "project_id", type: :list, values: -> { project_values }
    add_available_filter "period", type: :list, values: periods_values
    add_available_filter "status", type: :list, values: status_values
    add_available_filter "start_date", type: :date
    add_available_filter "end_date", type: :date
    add_available_filter "created_at", type: :date
    add_available_filter "updated_at", type: :date
    add_available_filter "created_by", type: :list, values: -> { author_values }
    add_available_filter "contract_number", type: :string
    add_available_filter "version_id", type: :list, values: -> { version_values }
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns
  end

  def sql_for_project_id_field(field, operator, value)
    sql_for_field(field, operator, value, Report.table_name, "project_id")
  end

  def joins_for_order_statement(order_options={})
    joins = []

    joins << "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Report.table_name}.project_id"
    joins << "LEFT JOIN #{User.table_name} users_created ON users_created.id = #{Report.table_name}.created_by"
    joins << "LEFT JOIN #{User.table_name} users_updated ON users_updated.id = #{Report.table_name}.updated_by"
    joins << "LEFT JOIN #{Version.table_name} ON #{Version.table_name}.id = #{Report.table_name}.version_id"

    joins.join(' ')
  end

  # Переопределяем метод для создания правильных условий фильтра
  def statement
    filters_clauses = []
    filters.each_key do |field|
      next if field == 'subproject_id'
      v = values_for(field).clone
      next unless v and !v.empty?
      operator = operator_for(field)

      # Добавляем условие в зависимости от поля
      sql = case field
            when 'created_by'
              sql_for_created_by_field(field, operator, v)
            when 'updated_by'
              sql_for_field(field, operator, v, Report.table_name, 'updated_by')
            else
              sql_for_field(field, operator, v, Report.table_name, field)
            end

      filters_clauses << "(#{sql})" if sql.present?
    end

    filters_clauses.any? ? filters_clauses.join(' AND ') : nil
  end

  def sql_for_created_by_field(field, operator, value)
    if value.delete('me')
      value.push(User.current.id.to_s)
    end
    sql_for_field(field, operator, value, Report.table_name, 'created_by')
  end

  def sql_for_version_id_field(field, operator, value)
    sql_for_field(field, operator, value, Version.table_name, 'id')
  end

  private

  def periods_values
    [['месячный', 'месячный'], ['квартальный', 'квартальный'],
     ['годовой', 'годовой'], ['прочее', 'прочее']]
  end

  def status_values
    [['черновик', 'черновик'], ['в_работе', 'в_работе'],
     ['сформирован', 'сформирован'], ['утвержден', 'утвержден']]
  end

  def project_values
    projects = Project.active.has_module(:report_registry)
    projects.collect{|s| [s.name, s.id.to_s]}
  end

  def version_values
    versions = Version.visible
    versions.collect{|s| ["#{s.project.name} - #{s.name}", s.id.to_s]}
  end

  def author_values
    values = [[l(:label_me), 'me']]
    values += User.active.sorted.map { |u| [u.name, u.id.to_s] }
    values
  end
end