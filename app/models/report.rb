# plugins/report_registry/app/models/report.rb
class Report < ActiveRecord::Base
  # Связь с пользователем, если нужны данные о создателе и обновителе
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true
  belongs_to :updater, class_name: 'User', foreign_key: 'updated_by', optional: true

  # Пример валидаций
  validates :name, presence: true
  validates :status, inclusion: { in: %w[черновик в_работе сформирован утвержден] }
end
