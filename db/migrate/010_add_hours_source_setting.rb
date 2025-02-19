# db/migrate/010_add_hours_source_setting.rb
class AddHoursSourceSetting < ActiveRecord::Migration[5.2]
  def up
    settings = Setting.plugin_report_registry || {}
    unless settings.key?('hours_source')
      settings['hours_source'] = 'estimated_hours'
      Setting.plugin_report_registry = settings
    end
  end

  def down
    settings = Setting.plugin_report_registry || {}
    settings.delete('hours_source')
    Setting.plugin_report_registry = settings
  end
end
