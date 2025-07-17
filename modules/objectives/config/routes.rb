Rails.application.routes.draw do
  resources :projects, only: %i[] do
    resources :objectives, controller: "objectives/objectives", only: %i[index]
  end
end
