class Issue < ActiveRecord::Base
  has_many :issue_reports, dependent: :destroy
  has_many :reports, through: :issue_reports
end