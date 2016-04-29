Rails.application.routes.draw do
  # Offload user control onto Devise - doing that once was enough for me.
  devise_for :users, :controllers => { :registrations => 'users/registrations' }

  # We can't have the default Rails welcome page, so let's just have a questions index as the front page.
  root                                  :to => 'questions#index'

  # Admins are important, let's make sure their routes override anything else.
  get    'admin',                       :to => 'admin#index'
  get    'admin/settings',              :to => 'site_settings#index'
  get    'admin/settings/:id/edit',     :to => 'site_settings#edit'
  post   'admin/settings/:id/edit',     :to => 'site_settings#update'
  patch  'admin/settings/:id/edit',     :to => 'site_settings#update'

  # Mods are also pretty important, I guess.
  get    'mod',                         :to => 'moderator#index'

  # Questions have a lot of actions...
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

  # Most of the users stuff is Devised, but it doesn't provide an index or profile.
  get    'users',                       :to => 'users#index'
  get    'users/:id',                   :to => 'users#show'

  # Surprisingly few routes for voting, considering its complexity.
  post   'votes/new',                   :to => 'votes#create'
  delete 'votes/:id',                   :to => 'votes#destroy'

  # Answers don't have quite as many as questions.
  get    'questions/:id/answer',        :to => 'answers#new'
  post   'questions/:id/answer',        :to => 'answers#create'
  get    'answers/:id/edit',            :to => 'answers#edit'
  post   'answers/:id/edit',            :to => 'answers#update'
  patch  'answers/:id/edit',            :to => 'answers#update'
  delete 'answers/:id/delete',          :to => 'answers#delete'
  patch  'answers/:id/delete',          :to => 'answers#undelete'

  # Nobody likes errors. Relegate them way down here.
  match  '/403',                        :to => 'errors#forbidden',                :via => :all
  match  '/404',                        :to => 'errors#not_found',                :via => :all
  match  '/409',                        :to => 'errors#conflict',                 :via => :all
  match  '/422',                        :to => 'errors#unprocessable_entity',     :via => :all
  match  '/500',                        :to => 'errors#internal_server_error',    :via => :all
end
