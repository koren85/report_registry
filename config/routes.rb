# config/routes.rb
Rails.application.routes.draw do
  # Глобальные маршруты отчетов
  resources :reports do
    resources :report_issues, only: [:index] do
      collection do
        get 'modal_issues'
        get 'search'
        post 'add_issues'
        delete 'remove_issue'
      end
    end

    member do
      patch 'approve'
    end
    collection do
      get 'load_project_versions'
    end
  end

  # Маршруты отчетов в контексте проекта
  resources :projects do
    resources :reports do
      resources :report_issues, only: [:index] do
        collection do
          get 'modal_issues'
          get 'search'
          post 'add_issues'
          delete 'remove_issue'
        end
      end

      member do
        patch 'approve'
      end
      collection do
        get 'load_project_versions'
      end
    end
  end
end