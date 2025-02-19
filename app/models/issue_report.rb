# plugins/report_registry/app/models/issue_report.rb
class IssueReport < ActiveRecord::Base
  belongs_to :issue
  belongs_to :report

  validates :reported_hours, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  before_create :set_default_report_title
  before_create :set_default_reported_hours

  private

  def set_default_report_title
    self.report_title ||= issue.subject if issue
  end

  def set_default_reported_hours
    return unless issue

    hours_source = Setting.plugin_report_registry['hours_source']
    source_value = case hours_source
                  when 'estimated_hours'
                    issue.estimated_hours
                  when 'spent_hours'
                    issue.spent_hours
                  when 'total_estimated_hours'
                    issue.total_estimated_hours
                  else
                    # Проверяем, является ли источник ID кастомного поля
                    custom_value = issue.custom_field_values.find { |v| v.custom_field_id.to_s == hours_source.to_s }
                    custom_value&.value
                  end

    self.reported_hours = source_value if source_value.present?
  end
end