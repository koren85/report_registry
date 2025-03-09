# lib/report_registry/issue_query_patch.rb
module ReportRegistry
  module IssueQueryPatch
    def self.included(base)
      base.class_eval do
        include InstanceMethods

        alias_method :initialize_available_filters_without_report, :initialize_available_filters
        alias_method :initialize_available_filters, :initialize_available_filters_with_report

        # Добавляем группу для отчетов в список групп фильтров
        class << self
          alias_method :available_columns_without_report, :available_columns=

          def available_columns=(v)
            available_columns_without_report(v)
            # Добавляем новую группу для фильтров отчетов
            unless Query.filters_groups.key?(:label_report_plural)
              Query.filters_groups[:label_report_plural] = [:registry_report_id]
            end
          end
        end
      end
    end

    module InstanceMethods
      def initialize_available_filters_with_report
        initialize_available_filters_without_report

        if User.current.allowed_to?(:view_reports, project, global: true)
          add_available_filter(
            "report_id",
            {
              type: :list_optional,
              name: l(:field_report),
              values: lambda { report_values },
              group: l(:label_report_plural)
            }
          )
        end
      end

      def sql_for_report_id_field(field, operator, value)
        case operator
        when "=", "!"
          report_ids = value.first.to_s.scan(/\d+/).map(&:to_i)
          if report_ids.present?
            operator_sql = operator == '=' ? 'IN' : 'NOT IN'
            sql = "#{Issue.table_name}.id #{operator_sql} (" +
              "SELECT DISTINCT #{IssueReport.table_name}.issue_id " +
              "FROM #{IssueReport.table_name} " +
              "WHERE #{IssueReport.table_name}.report_id #{operator_sql} (#{report_ids.join(',')}))"

            if project
              sql = "#{sql} AND #{Issue.table_name}.project_id = #{project.id}"
            end

            sql
          else
            "1=0"
          end
        when "!*"
          "NOT EXISTS (SELECT 1 FROM #{IssueReport.table_name} WHERE #{IssueReport.table_name}.issue_id = #{Issue.table_name}.id)"
        when "*"
          "EXISTS (SELECT 1 FROM #{IssueReport.table_name} WHERE #{IssueReport.table_name}.issue_id = #{Issue.table_name}.id)"
        end
      end

      private

      def report_values
        scope = project ? Report.where(project_id: project.id) : Report.visible
        scope.order(:name).map { |r| ["#{r.project.name} - #{r.name}", r.id.to_s] }
      end
    end
  end
end

unless IssueQuery.included_modules.include?(ReportRegistry::IssueQueryPatch)
  IssueQuery.send(:include, ReportRegistry::IssueQueryPatch)
end