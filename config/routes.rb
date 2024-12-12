Rails.application.routes.draw do
  # Глобальные маршруты отчетов
  resources :reports do
    member do
      patch 'approve'
    end
    collection do
      get 'load_project_versions'
    end

    # Маршруты для работы с задачами отчета
    resources :report_issues, only: [:index] do
      collection do
        get 'search'
        post 'add_issues'
        delete 'remove_issue'
      end
    end
  end

  # Маршруты отчетов в контексте проекта
  resources :projects do
    resources :reports do
      member do
        patch 'approve'
      end
      collection do
        get 'load_project_versions'
      end
    end
  end
end