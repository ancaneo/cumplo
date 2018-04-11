Rails.application.routes.draw do
  get 'index' => 'management#index'
  root 'management#index'
end
