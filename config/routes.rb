Rails.application.routes.draw do
  devise_for :users

  get    'admin',                       :to => 'admin#index'
  get    'admin/settings',              :to => 'site_settings#index'
  get    'admin/settings/:id/edit',     :to => 'site_settings#edit'
  post   'admin/settings/:id/edit',     :to => 'site_settings#update'
  patch  'admin/settings/:id/edit',     :to => 'site_settings#update'

  get    'mod',                         :to => 'moderator#index'

  get    'questions',                   :to => 'questions#index'
  get    'questions/:id',               :to => 'questions#show'
  get    'questions/tagged/:tag'        :to => 'questions#tagged'
end
