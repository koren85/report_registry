class AddSubtaskFieldSetting < ActiveRecord::Migration[5.2]
  def up
    # Добавляем настройку для поля подзадачи, если её еще нет
    settings = Setting.plugin_report_registry || {}
    unless settings.key?('subtask_field_id')
      settings['subtask_field_id'] = nil
      Setting.plugin_report_registry = settings
    end
  end

  def down
    settings = Setting.plugin_report_registry || {}
    settings.delete('subtask_field_id')
    Setting.plugin_report_registry = settings
  end
end