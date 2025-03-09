# config/routes.rb

Rails.application.routes.draw do
  resources :registry_reports do
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
    resources :registry_reports do
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
  # Маршруты для функционала планирования
  resources :projects do
    resources :work_plans, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      member do
        patch 'approve'
        patch 'close'
        post 'create_report'
        # Новый маршрут для создания категорий из плана работ
        post 'create_categories'
      end

      resources :work_plan_categories, only: [:show, :new, :create, :edit, :update, :destroy] do
        resources :work_plan_tasks, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
          member do
            patch 'distribute_hours'
          end

          collection do
            get 'search_issues'
          end
        end
      end
    end

    # Добавляем маршрут для создания плана работ для версии
    resources :versions, only: [] do
      resources :work_plans, only: [:new, :create]
    end
  end

  # Маршруты для интеграции отчетов с планами
  resources :registry_reports, only: [] do
    member do
      get 'plan_tasks'
      post 'add_plan_tasks'
    end
  end

  # Маршруты для проектного контекста отчетов
  resources :projects do
    resources :registry_reports, only: [] do
      member do
        get 'plan_tasks'
        post 'add_plan_tasks'
      end
    end
  end

  # Маршрут для глобального доступа к планам работ
  get 'work_plans', to: 'work_plans#global_index', as: 'global_work_plans'

  # Маршрут для просмотра отдельного плана работ вне контекста проекта
  get 'work_plans/:id', to: 'work_plans#show', as: 'work_plan'

end