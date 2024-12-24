# lib/report_registry/issue_patch.rb
module ReportRegistry
  module IssuePatch
    def self.included(base)
      base.class_eval do
        has_many :issue_reports, dependent: :destroy
        has_many :reports, through: :issue_reports
      end
    end
  end
end
