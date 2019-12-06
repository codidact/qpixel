Rails.application.routes.draw do
  devise_for :users

  root                                  to: 'questions#index'

  get    'admin',                       to: 'admin#index', as: :admin
  get    'admin/settings',              to: 'site_settings#index', as: :site_settings
  get    'admin/settings/:name',        to: 'site_settings#show', as: :site_setting
  post   'admin/settings/:name',        to: 'site_settings#update', as: :update_site_setting
  delete 'admin/users/delete/:id',      to: 'users#soft_delete', as: :soft_delete_user

  get    'mod',                         to: 'moderator#index', as: :moderator
  get    'mod/deleted/questions',       to: 'moderator#recently_deleted_questions', as: :recently_deleted_questions
  get    'mod/deleted/answers',         to: 'moderator#recently_deleted_answers', as: :recently_deleted_answers
  get    'mod/undeleted/questions',     to: 'moderator#recently_undeleted_questions', as: :recently_undeleted_questions
  get    'mod/undeleted/answers',       to: 'moderator#recently_undeleted_answers', as: :recently_undeleted_answers
  get    'mod/flags',                   to: 'flags#queue', as: :flag_queue
  post   'mod/flags/:id/resolve',       to: 'flags#resolve', as: :resolve_flag
  get    'mod/votes',                   to: 'suspicious_votes#index', as: :suspicious_votes
  patch  'mod/votes/investigated/:id',  to: 'suspicious_votes#investigated', as: :investigated_suspicious_vote
  get    'mod/votes/user/:id',          to: 'suspicious_votes#user', as: :suspicious_votes_user
  delete 'mod/users/destroy/:id',       to: 'users#destroy', as: :destroy_user

  get    'questions',                   to: 'questions#index', as: :questions
  get    'questions/feed',              to: 'questions#feed', as: :question_feed
  get    'questions/ask',               to: 'questions#new', as: :new_question
  post   'questions/ask',               to: 'questions#create', as: :create_question
  get    'questions/tagged/:tag',       to: 'questions#tagged', as: :questions_tagged
  get    'questions/:id',               to: 'questions#show', as: :question
  get    'questions/:id/edit',          to: 'questions#edit', as: :edit_question
  patch  'questions/:id/edit',          to: 'questions#update', as: :update_question
  delete 'questions/:id/delete',        to: 'questions#destroy', as: :delete_question
  post   'questions/:id/undelete',      to: 'questions#undelete', as: :undelete_question
  post   'questions/:id/close',         to: 'questions#close', as: :close_question
  post   'questions/:id/reopen',        to: 'questions#reopen', as: :reopen_question

  get    'posts/:id/history',           to: 'post_history#post', as: :post_history

  get    'users',                       to: 'users#index', as: :users
  get    'users/stack-redirect',        to: 'users#stack_redirect', as: :stack_redirect
  post   'users/claim-content',         to: 'users#transfer_se_content', as: :claim_stack_content
  get    'users/:id',                   to: 'users#show', as: :user
  get    'users/:id/mod',               to: 'users#mod', as: :mod_user
  get    'users/me/notifications',      to: 'notifications#index', as: :notifications
  get    'users/edit/profile',          to: 'users#edit_profile', as: :edit_user_profile
  patch  'users/edit/profile',          to: 'users#update_profile', as: :update_user_profile

  post   'notifications/:id/read',      to: 'notifications#read', as: :read_notifications
  post   'notifications/read_all',      to: 'notifications#read_all', as: :read_all_notifications

  post   'votes/new',                   to: 'votes#create', as: :create_vote
  delete 'votes/:id',                   to: 'votes#destroy', as: :destroy_vote

  get    'questions/:id/answer',        to: 'answers#new', as: :new_answer
  post   'questions/:id/answer',        to: 'answers#create', as: :create_answer
  get    'answers/:id/edit',            to: 'answers#edit', as: :edit_answer
  patch  'answers/:id/edit',            to: 'answers#update', as: :update_answer
  delete 'answers/:id/delete',          to: 'answers#destroy', as: :delete_answer
  post   'answers/:id/delete',          to: 'answers#undelete', as: :undelete_answer

  post   'flags/new',                   to: 'flags#new', as: :new_flag

  post   'comments/new',                to: 'comments#create', as: :create_comment
  get    'comments/:id',                to: 'comments#show', as: :comment
  post   'comments/:id/edit',           to: 'comments#update', as: :update_comment
  delete 'comments/:id/delete',         to: 'comments#destroy', as: :delete_comment
  patch  'comments/:id/delete',         to: 'comments#undelete', as: :undelete_comment

  match  '/403',                        to: 'errors#forbidden',                via: :all
  match  '/404',                        to: 'errors#not_found',                via: :all
  match  '/409',                        to: 'errors#conflict',                 via: :all
  match  '/422',                        to: 'errors#unprocessable_entity',     via: :all
  match  '/500',                        to: 'errors#internal_server_error',    via: :all
end
