Rails.application.routes.draw do
  devise_for :users, :controllers => { :registrations => 'users/registrations' }

  root                                  :to => 'questions#index'

  get    'admin',                       :to => 'admin#index'
  get    'admin/settings',              :to => 'site_settings#index'
  get    'admin/settings/:id/edit',     :to => 'site_settings#edit'
  post   'admin/settings/:id/edit',     :to => 'site_settings#update'
  patch  'admin/settings/:id/edit',     :to => 'site_settings#update'

  get    'mod',                         :to => 'moderator#index'

  get    'questions',                   :to => 'questions#index'
  get    'questions/tagged/:tag',       :to => 'questions#tagged'
  get    'questions/:id',               :to => 'questions#show'

  get    'users',                       :to => 'users#index'
  get    'users/:id',                   :to => 'users#show'

  post   'votes/new',                   :to => 'votes#create'
  delete 'votes/:id',                   :to => 'votes#destroy'
end
