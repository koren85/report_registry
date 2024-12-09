RedmineApp::Application.routes.draw do
  # Глобальные маршруты
  resources :reports do
    member do
      patch :approve
    end
    collection do
      get :load_project_versions
    end
  end

  # Маршруты в контексте проекта
  resources :projects do
    resources :reports do
      member do
        patch :approve
      end
    end
  end
end