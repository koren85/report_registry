Rails.application.routes.draw do
  resources :reports do
    resources :report_issues do
      collection do
        get 'modal_issues'
        get 'search'
        post 'add_issues'
        delete 'remove_issues'
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

  resources :projects do
    resources :reports do
      resources :report_issues do
        collection do
          get 'modal_issues'
          get 'search'
          post 'add_issues'
          delete 'remove_issues'
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