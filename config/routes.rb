RedmineApp::Application.routes.draw do
  # Глобальные маршруты
  resources :reports do
    member do
      patch :approve
    end
    collection do
      get :load_project_versions
      get :load_project_issues     # новый маршрут для загрузки задач
    end
  end

  # Маршруты в контексте проекта
  resources :projects do
    resources :reports do
      member do
        patch :approve
      end
    end

    # Новые маршруты для работы с задачами
    resources :issues, only: [:create] do
      collection do
        get :table_data    # для получения данных таблицы
        get :statuses     # для получения списка статусов при создании задачи
      end
    end
  end
end