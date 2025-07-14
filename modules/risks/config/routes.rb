Rails.application.routes.draw do
  resources :projects, only: %i[] do
    resources :risks, controller: "risks/risks", only: %i[index]
  end
end
