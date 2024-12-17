# config/routes.rb
Rails.application.routes.draw do
  resources :reports do
    resources :report_issues, only: [:index] do
      collection do
        get 'modal_issues'
        get 'search'
        post 'add_issues'
        delete 'remove_issues'
      end
      member do
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
      resources :report_issues, only: [:index] do
        collection do
          get 'modal_issues'
          get 'search'
          post 'add_issues'
          delete 'remove_issues'
        end
        member do
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