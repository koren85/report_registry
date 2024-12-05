# plugins/report_registry/config/routes.rb
RedmineApp::Application.routes.draw do
  # Создаем ресурс reports с доступом только к экшену index
  resources :reports, only: [:index]
end
