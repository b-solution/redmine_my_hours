# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
  resources :my_hours, only: [:index] do
  end
end
