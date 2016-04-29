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
  get    'questions/ask',               :to => 'questions#new'
  post   'questions/ask',               :to => 'questions#create'
  get    'questions/tagged/:tag',       :to => 'questions#tagged'
  get    'questions/:id',               :to => 'questions#show'
  get    'questions/:id/edit',          :to => 'questions#edit'
  post   'questions/:id/edit',          :to => 'questions#update'
  patch  'questions/:id/edit',          :to => 'questions#update'
  delete 'questions/:id/delete',        :to => 'questions#destroy'
  patch  'questions/:id/delete',        :to => 'questions#undelete'

  get    'users',                       :to => 'users#index'
  get    'users/:id',                   :to => 'users#show'

  post   'votes/new',                   :to => 'votes#create'
  delete 'votes/:id',                   :to => 'votes#destroy'

  get    'questions/answer/:id',        :to => 'answers#new'
  post   'questions/answer/:id',        :to => 'answers#create'
  get    'answers/:id/edit',            :to => 'answers#edit'
  post   'answers/:id/edit',            :to => 'answers#update'
  patch  'answers/:id/edit',            :to => 'answers#update'
  delete 'answers/:id/delete',          :to => 'answers#delete'
  patch  'answers/:id/delete',          :to => 'answers#undelete'

  match  '/403',                        :to => 'errors#forbidden',                :via => :all
  match  '/404',                        :to => 'errors#not_found',                :via => :all
  match  '/409',                        :to => 'errors#conflict',                 :via => :all
  match  '/422',                        :to => 'errors#unprocessable_entity',     :via => :all
  match  '/500',                        :to => 'errors#internal_server_error',    :via => :all
end
