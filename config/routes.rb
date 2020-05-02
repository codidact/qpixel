Rails.application.routes.draw do
  devise_for :users

  root                                     to: 'categories#homepage'

  get    'admin',                          to: 'admin#index', as: :admin
  get    'admin/errors',                   to: 'admin#error_reports', as: :admin_error_reports
  get    'admin/settings',                 to: 'site_settings#index', as: :site_settings
  get    'admin/settings/global',          to: 'site_settings#global', as: :global_settings
  get    'admin/settings/:name',           to: 'site_settings#show', as: :site_setting
  post   'admin/settings/:name',           to: 'site_settings#update', as: :update_site_setting
  delete 'admin/users/delete/:id',         to: 'users#soft_delete', as: :soft_delete_user
  get    'admin/privileges',               to: 'admin#privileges', as: :admin_privileges
  get    'admin/privileges/:name',         to: 'admin#show_privilege', as: :admin_privilege
  post   'admin/privileges/:name',         to: 'admin#update_privilege', as: :admin_update_privilege

  get    'close_reasons',                  to: 'close_reasons#index', as: :close_reasons
  get    'close_reasons/edit/:id',         to: 'close_reasons#edit', as: :close_reason
  patch  'close_reasons/edit/:id',         to: 'close_reasons#update', as: :update_close_reason
  get    'close_reasons/new',              to: 'close_reasons#new', as: :new_close_reason
  post   'close_reasons/new',              to: 'close_reasons#create', as: :create_close_reason

  scope  'admin/tag-sets' do
    root                                   to: 'tag_sets#index', as: :tag_sets
    get    'global',                       to: 'tag_sets#global', as: :global_tag_sets
    get    ':id',                          to: 'tag_sets#show', as: :tag_set
    post   ':id/edit',                     to: 'tag_sets#update', as: :update_tag_set
  end

  scope 'admin/licenses' do
    root                                   to: 'licenses#index', as: :licenses
    get    'new',                          to: 'licenses#new', as: :new_license
    post   'new',                          to: 'licenses#create', as: :create_license
    get    ':id/edit',                     to: 'licenses#edit', as: :edit_license
    patch  ':id/edit',                     to: 'licenses#update', as: :update_license
    post   ':id/toggle',                   to: 'licenses#toggle', as: :toggle_license
  end

  get    'mod',                            to: 'moderator#index', as: :moderator
  get    'mod/deleted/questions',          to: 'moderator#recently_deleted_questions', as: :recently_deleted_questions
  get    'mod/deleted/answers',            to: 'moderator#recently_deleted_answers', as: :recently_deleted_answers
  get    'mod/undeleted/questions',        to: 'moderator#recently_undeleted_questions', as: :recently_undeleted_questions
  get    'mod/undeleted/answers',          to: 'moderator#recently_undeleted_answers', as: :recently_undeleted_answers
  get    'mod/flags',                      to: 'flags#queue', as: :flag_queue
  post   'mod/flags/:id/resolve',          to: 'flags#resolve', as: :resolve_flag
  get    'mod/votes',                      to: 'suspicious_votes#index', as: :suspicious_votes
  patch  'mod/votes/investigated/:id',     to: 'suspicious_votes#investigated', as: :investigated_suspicious_vote
  get    'mod/votes/user/:id',             to: 'suspicious_votes#user', as: :suspicious_votes_user
  delete 'mod/users/destroy/:id',          to: 'users#destroy', as: :destroy_user

  get    'questions',                      to: 'questions#index', as: :questions
  get    'questions/lottery',              to: 'questions#lottery', as: :questions_lottery
  get    'meta',                           to: 'questions#meta', as: :meta
  get    'questions/feed',                 to: 'questions#feed', as: :question_feed
  get    'questions/ask',                  to: 'questions#new', as: :new_question
  get    'meta/ask',                       to: 'questions#new_meta', as: :new_meta_question
  post   'questions/ask',                  to: 'questions#create', as: :create_question
  get    'questions/tagged/:tag_set/:tag', to: 'questions#tagged', as: :questions_tagged
  get    'questions/:id',                  to: 'questions#show', as: :question
  get    'questions/:id/edit',             to: 'questions#edit', as: :edit_question
  patch  'questions/:id/edit',             to: 'questions#update', as: :update_question
  delete 'questions/:id/delete',           to: 'questions#destroy', as: :delete_question
  post   'questions/:id/undelete',         to: 'questions#undelete', as: :undelete_question
  post   'questions/:id/close',            to: 'questions#close', as: :close_question
  post   'questions/:id/reopen',           to: 'questions#reopen', as: :reopen_question

  get    'posts/:id/history',              to: 'post_history#post', as: :post_history
  get    'posts/search',                   to: 'search#search', as: :search
  post   'posts/upload',                   to: 'posts#upload', as: :upload

  get    'posts/:id/edit',                 to: 'posts#edit', as: :edit_post
  patch  'posts/:id/edit',                 to: 'posts#update', as: :update_post

  get    'posts/new-help',                 to: 'posts#new_help', as: :new_help_post
  post   'posts/new-help',                 to: 'posts#create_help', as: :create_help_post
  get    'posts/:id/edit-help',            to: 'posts#edit_help', as: :edit_help_post
  patch  'posts/:id/edit-help',            to: 'posts#update_help', as: :update_help_post

  get    'policy/:slug',                   to: 'posts#document', as: :policy
  get    'help/:slug',                     to: 'posts#document', as: :help

  get    'tags',                           to: 'tags#index', as: :tags

  get    'users',                          to: 'users#index', as: :users
  get    'users/stack-redirect',           to: 'users#stack_redirect', as: :stack_redirect
  post   'users/claim-content',            to: 'users#transfer_se_content', as: :claim_stack_content
  get    'users/:id',                      to: 'users#show', as: :user
  get    'users/:id/flags',                to: 'flags#history', as: :flag_history
  get    'users/:id/mod',                  to: 'users#mod', as: :mod_user
  get    'users/:id/posts/:type',          to: 'users#posts', as: :user_posts
  get    'users/me/notifications',         to: 'notifications#index', as: :notifications
  get    'users/edit/profile',             to: 'users#edit_profile', as: :edit_user_profile
  patch  'users/edit/profile',             to: 'users#update_profile', as: :update_user_profile
  post   'users/:id/mod/toggle-role',      to: 'users#role_toggle', as: :toggle_user_role

  post   'notifications/:id/read',         to: 'notifications#read', as: :read_notifications
  post   'notifications/read_all',         to: 'notifications#read_all', as: :read_all_notifications

  post   'votes/new',                      to: 'votes#create', as: :create_vote
  delete 'votes/:id',                      to: 'votes#destroy', as: :destroy_vote

  get    'questions/:id/answer',           to: 'answers#new', as: :new_answer
  post   'questions/:id/answer',           to: 'answers#create', as: :create_answer
  get    'answers/:id/edit',               to: 'answers#edit', as: :edit_answer
  patch  'answers/:id/edit',               to: 'answers#update', as: :update_answer
  delete 'answers/:id/delete',             to: 'answers#destroy', as: :delete_answer
  post   'answers/:id/delete',             to: 'answers#undelete', as: :undelete_answer

  post   'flags/new',                      to: 'flags#new', as: :new_flag

  post   'comments/new',                   to: 'comments#create', as: :create_comment
  get    'comments/post/:post_id',         to: 'comments#post', as: :post_comments
  get    'comments/:id',                   to: 'comments#show', as: :comment
  post   'comments/:id/edit',              to: 'comments#update', as: :update_comment
  delete 'comments/:id/delete',            to: 'comments#destroy', as: :delete_comment
  patch  'comments/:id/delete',            to: 'comments#undelete', as: :undelete_comment

  get    'q/:id',                          to: 'posts#share_q', as: :share_question
  get    'a/:qid/:id',                     to: 'posts#share_a', as: :share_answer

  get    'subscriptions/new/:type',        to: 'subscriptions#new', as: :new_subscription
  post   'subscriptions/new',              to: 'subscriptions#create', as: :create_subscription
  get    'subscriptions',                  to: 'subscriptions#index', as: :subscriptions
  post   'subscriptions/:id/enable',       to: 'subscriptions#enable', as: :enable_subscription
  delete 'subscriptions/:id',              to: 'subscriptions#destroy', as: :destroy_subscription

  scope 'reports' do
    root                                   to: 'reports#users', as: :users_report
    get    'subscriptions',                to: 'reports#subscriptions', as: :subscriptions_report
    get    'posts',                        to: 'reports#posts', as: :posts_report
  end

  get    'help',                           to: 'posts#help_center', as: :help_center

  scope 'categories' do
    root                                           to: 'categories#index', as: :categories
    get    'new',                                  to: 'categories#new', as: :new_category
    post   'new',                                  to: 'categories#create', as: :create_category
    get    ':category_id/posts/new/:post_type_id', to: 'posts#new', as: :new_post
    post   ':category_id/posts/new/:post_type_id', to: 'posts#create', as: :create_post
    get    ':id',                                  to: 'categories#show', as: :category
    get    ':id/edit',                             to: 'categories#edit', as: :edit_category
    post   ':id/edit',                             to: 'categories#update', as: :update_category
    delete ':id',                                  to: 'categories#destroy', as: :destroy_category
  end

  get   '403',                           to: 'errors#forbidden'
  get   '404',                           to: 'errors#not_found'
  get   '409',                           to: 'errors#conflict'
  get   '422',                           to: 'errors#unprocessable_entity'
  get   '500',                           to: 'errors#internal_server_error'
end
