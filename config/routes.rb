# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
  resources :my_hours, only: [:index] do
    collection do
      get 'overview'
    end
  end
end
resources :my_hours, only: [] do
  collection do
    get 'overview'
  end
end
