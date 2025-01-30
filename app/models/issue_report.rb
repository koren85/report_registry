# plugins/report_registry/app/models/issue_report.rb
class IssueReport < ActiveRecord::Base
  belongs_to :issue
  belongs_to :report

  before_create :set_default_report_title

  private

  def set_default_report_title
    self.report_title ||= issue.subject if issue
  end
end
