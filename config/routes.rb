# config/routes.rb

Rails.application.routes.draw do
  resources :reports do
    resources :report_issues do
      collection do
        get 'modal_issues'
        get 'search'
        get 'select_search' # новый для select2 в форме
        post 'add_issues'
        delete 'remove_issues'
        delete 'remove_issue'
        post 'add', action: 'add_issue'
      end
      # Добавляем маршрут для обновления названия задачи
      member do
        patch 'update_title'
        patch 'update_hours'  # Добавляем к существующему update_title
      end
    end
    member do
      patch 'approve'
      # Добавляем стандартный маршрут для поиска задач в отчете
      get 'issues/search', to: 'report_issues#search'
    end
    collection do
      get 'load_project_versions'
    end
  end

  resources :projects do
    resources :reports do
      resources :report_issues do
        collection do
          get 'modal_issues'
          get 'search'
          get 'select_search' # новый для select2 в форме
          post 'add_issues'
          delete 'remove_issues'
          delete 'remove_issue'
          delete 'remove_single_issue/:issue_id', action: 'remove_issue', as: 'remove_single_issue'
          post 'add', action: 'add_issue'
        end
        # Добавляем маршрут для обновления названия задачи
        member do
          patch 'update_title'
          patch 'update_hours'  # Добавляем к существующему update_title
        end
      end
      member do
        patch 'approve'
        # Добавляем стандартный маршрут для поиска задач в отчете в контексте проекта
        get 'issues/search', to: 'report_issues#search'
      end
      collection do
        get 'load_project_versions'
      end
    end

    resources :issues do
      resources :report_issues, only: [] do
        collection do
          post 'add', action: 'add_issue'
          delete 'remove', action: 'remove_issue'
        end
      end
    end
  end
end