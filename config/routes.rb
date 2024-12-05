RedmineApp::Application.routes.draw do
  # Глобальная страница отчётов с возможностью создания
  resources :reports, only: [:index, :new, :create]

  # Страница отчётов для конкретного проекта
  scope 'projects/:project_id' do
    resources :reports, only: [:index, :new, :create, :edit, :update, :destroy] do
      member do
        patch :approve
      end
    end
  end
end
