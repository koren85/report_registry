# plugins/report_registry/app/models/issue_report.rb
class IssueReport < ActiveRecord::Base
  belongs_to :issue
  belongs_to :report
end
