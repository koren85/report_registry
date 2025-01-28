# plugins/report_registry/app/models/report.rb
class Report < ActiveRecord::Base
  before_save :set_updater

  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true
  belongs_to :updater, class_name: 'User', foreign_key: 'updated_by', optional: true

  belongs_to :project
  belongs_to :version, optional: true

  # Добавляем валидацию уникальности связи issue_reports
  has_many :issue_reports, dependent: :destroy
  has_many :issues, -> { distinct }, through: :issue_reports


  # Валидации
  validates :name, presence: true, length: { maximum: 254 }
  validates :project_id, presence: true
  validates :status, inclusion: { in: %w[черновик в_работе сформирован утвержден] }



  # Методы проверки прав
  def visible?(user=User.current)
    return true if user.admin?

    if project
      user.allowed_to?(:view_reports, project) ||
        user.allowed_to?(:manage_reports, project)
    else
      user.allowed_to_globally?(:manage_reports_global)
    end
  end

  def editable?(user=User.current)
    return true if user.admin?

    if project
      user.allowed_to?(:manage_reports, project)
    else
      user.allowed_to_globally?(:manage_reports_global)
    end
  end

  private

  def set_updater
    if changed? || issue_reports.loaded? && issue_reports.any? { |ir| ir.changed? || ir.marked_for_destruction? }
      self.updated_by = User.current.id
      # Используем updated_at вместо updated_on
      self.updated_at = Time.current
    end
  end
end