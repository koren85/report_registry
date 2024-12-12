RedmineApp::Application.routes.draw do
  # Глобальные маршруты
  resources :reports do
    member do
      patch :approve
    end
    collection do
      get :load_project_versions
      get :load_project_issues
    end
  end

  resources :issues do
    collection do
      get 'available_statuses'
    end
  end

  # Маршруты в контексте проекта
  resources :projects do
    scope module: 'report_registry' do
      get 'available_assignees', to: 'issues#available_assignees'
      get 'issues/table_data', to: 'issues#table_data'

      resources :issues, only: [:create] do
        collection do
          get :statuses
        end
      end
    end

    resources :reports do
      member do
        patch :approve
      end
    end
  end
end