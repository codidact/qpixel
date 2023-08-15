Rails.application.routes.draw do
  # Add normal sign in/sign up, confirmations, registrations, unlocking and password editing routes only if no SSO or mixed sign in.
  devise_for :users, only: %i[sessions registrations confirmations unlock passwords],
             controllers: { sessions: 'users/sessions', registrations: 'users/registrations' },
             constraints: { url: lambda { |_url| SiteSetting['MixedSignIn'] || !SiteSetting['SsoSignIn'] } }
  # Add SAML routes only when SAML enabled
  devise_for :users, only: :saml_authenticatable,
             controllers: { saml_sessions: 'users/saml_sessions' },
             constraints: { url: lambda { |_url| SiteSetting['SsoSignIn'] } }
  # Add any other devise routes that may exist that we did not add yet
  devise_for :users, skip: %i[sessions registrations confirmations unlock passwords saml_authenticatable]
  devise_scope :user do
    get  'users/2fa/login',                to: 'users/sessions#verify_2fa', as: :login_verify_2fa
    post 'users/2fa/login',                to: 'users/sessions#verify_code', as: :login_verify_code
    get  'users/saml/sign_in_request_from_other/:id', to: 'users/saml_sessions#sign_in_request_from_other', as: :sign_in_request_from_other
    get  'users/saml/sign_in_return_from_base',       to: 'users/saml_sessions#sign_in_return_from_base', as: :sign_in_return_from_base
    get  'users/saml/after_sign_in_check',            to: 'users/saml_sessions#after_sign_in_check', as: :after_sign_in_check
  end

  root                                     to: 'categories#homepage'

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?  
  
  scope 'admin' do
    root                                   to: 'admin#index', as: :admin
    get    'errors',                       to: 'admin#error_reports', as: :admin_error_reports

    get    'settings',                     to: 'site_settings#index', as: :site_settings
    get    'settings/global',              to: 'site_settings#global', as: :global_settings
    get    'settings/:name',               to: 'site_settings#show', as: :site_setting
    post   'settings/:name',               to: 'site_settings#update', as: :update_site_setting

    delete 'users/delete/:id',             to: 'users#soft_delete', as: :soft_delete_user

    get    'privileges',                   to: 'admin#privileges', as: :admin_privileges
    get    'privileges/:name',             to: 'admin#show_privilege', as: :admin_privilege
    post   'privileges/:name',             to: 'admin#update_privilege', as: :admin_update_privilege

    get    'mod-email',                    to: 'admin#admin_email', as: :moderator_email
    post   'mod-email',                    to: 'admin#send_admin_email', as: :send_moderator_email
    get    'email-all',                    to: 'admin#all_email', as: :email_all
    post   'email-all',                    to: 'admin#send_all_email', as: :send_all_email

    get    'audits',                       to: 'admin#audit_log', as: :audit_log

    get    'new-site',                     to: 'admin#new_site', as: :new_site
    post   'new-site',                     to: 'admin#create_site', as: :create_site

    get    'setup',                        to: 'admin#setup', as: :setup
    post   'setup',                        to: 'admin#setup_save', as: :setup_save

    get    'impersonate/stop',             to: 'admin#change_back', as: :stop_impersonating
    post   'impersonate/stop',             to: 'admin#verify_elevation', as: :verify_elevation
    post   'impersonate/:id',              to: 'admin#change_users', as: :impersonate
    get    'impersonate/:id',              to: 'admin#impersonate', as: :start_impersonating

    scope 'post-types' do
      root                                 to: 'post_types#index', as: :post_types
      get    'new',                        to: 'post_types#new', as: :new_post_type
      post   'new',                        to: 'post_types#create', as: :create_post_type
      get    ':id/edit',                   to: 'post_types#edit', as: :edit_post_type
      patch  ':id/edit',                   to: 'post_types#update', as: :update_post_type
    end
  end

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

  scope 'mod' do
    root                                   to: 'moderator#index', as: :moderator
    get    'deleted',                      to: 'moderator#recently_deleted_posts', as: :recently_deleted_posts
    get    'comments',                     to: 'moderator#recent_comments', as: :recent_comments
    get    'flags',                        to: 'flags#queue', as: :flag_queue
    get    'flags/handled',                to: 'flags#handled', as: :handled_flags
    get    'flags/escalated',              to: 'flags#escalated_queue', as: :escalated_flags
    delete 'users/destroy/:id',            to: 'users#destroy', as: :destroy_user
    get    'users/votes/:id',              to: 'moderator#user_vote_summary', as: :mod_vote_summary
    post   'flags/:id/resolve',            to: 'flags#resolve', as: :resolve_flag
    post   'flags/:id/escalate',           to: 'flags#escalate', as: :escalate_flag

    scope 'featured' do
      root                                 to: 'pinned_links#index', as: :pinned_links
      get   'new',                         to: 'pinned_links#new', as: :new_pinned_link
      post  'new',                         to: 'pinned_links#create', as: :create_pinned_link
      get   ':id/edit',                    to: 'pinned_links#edit', as: :edit_pinned_link
      patch ':id/edit',                    to: 'pinned_links#update', as: :update_pinned_link
    end
  end

  get    'questions/lottery',              to: 'questions#lottery', as: :questions_lottery

  scope 'posts/reactions' do
    root                                  to: 'reactions#index', as: :reactions
    get   ':id/edit',                     to: 'reactions#edit', as: :edit_reaction
    patch ':id/edit',                     to: 'reactions#update', as: :update_reaction
    get   'new',                          to: 'reactions#new', as: :new_reaction
    post  'new',                          to: 'reactions#create', as: :create_reaction

    post  'add',                          to: 'reactions#add', as: :add_reaction
    post  'retract',                      to: 'reactions#retract', as: :retract_reaction
  end

  scope 'posts' do
    scope 'suggested-edit' do
      get    ':id',           to: 'suggested_edit#show', as: :suggested_edit
      post   ':id/approve',   to: 'suggested_edit#approve', as: :suggested_edit_approve
      post   ':id/reject',    to: 'suggested_edit#reject', as: :suggested_edit_reject
    end

    get    'new/:post_type',               to: 'posts#new', as: :new_post
    get    'new/:post_type/respond/:parent', to: 'posts#new', as: :new_response
    get    'new/:post_type/:category',     to: 'posts#new', as: :new_category_post
    post   'new/:post_type',               to: 'posts#create', as: :create_post
    post   'new/:post_type/respond/:parent', to: 'posts#create', as: :create_response
    post   'new/:post_type/:category',     to: 'posts#create', as: :create_category_post
    get    'search',                       to: 'search#search', as: :search
    get    'promoted',                     to: 'moderator#promotions', as: :promoted_posts
    get    'types',                        to: 'post_types#list', as: :post_types_list
    post   'upload',                       to: 'posts#upload', as: :upload
    post   'save-draft',                   to: 'posts#save_draft', as: :save_draft
    post   'delete-draft',                 to: 'posts#delete_draft', as: :delete_draft

    get    ':id',                          to: 'posts#show', as: :post
    get    ':id/history',                  to: 'post_history#post', as: :post_history
    get    ':id/edit',                     to: 'posts#edit', as: :edit_post
    patch  ':id/edit',                     to: 'posts#update', as: :update_post
    post   ':id/close',                    to: 'posts#close', as: :close_post
    post   ':id/reopen',                   to: 'posts#reopen', as: :reopen_post
    post   ':id/delete',                   to: 'posts#delete', as: :delete_post
    post   ':id/restore',                  to: 'posts#restore', as: :restore_post
    post   ':id/category',                 to: 'posts#change_category', as: :change_category
    post   ':id/toggle_comments',          to: 'posts#toggle_comments', as: :post_comments_allowance_toggle
    post   ':id/lock',                     to: 'posts#lock', as: :post_lock
    post   ':id/unlock',                   to: 'posts#unlock', as: :post_unlock
    post   ':id/feature',                  to: 'posts#feature', as: :post_feature
    post   ':id/promote',                  to: 'moderator#nominate_promotion', as: :promote_post
    delete ':id/promote',                  to: 'moderator#remove_promotion', as: :remove_post_promotion

    get    ':id/:answer',                  to: 'posts#show', as: :answer_post
  end

  get    'policy/:slug',                   to: 'posts#document', as: :policy
  get    'help/:slug',                     to: 'posts#document', as: :help

  get    'tags',                           to: 'tags#index', as: :tags

  scope 'users/two-factor' do
    root                                   to: 'two_factor#tf_status', as: :two_factor_status
    post 'enable',                         to: 'two_factor#enable_2fa', as: :two_factor_enable
    get  'enable/code',                    to: 'two_factor#enable_code', as: :two_factor_enable_code
    post 'enable/code',                    to: 'two_factor#confirm_enable_code', as: :two_factor_confirm_enable
    get  'disable/code',                   to: 'two_factor#disable_code', as: :two_factor_disable_code
    post 'disable/code',                   to: 'two_factor#confirm_disable_code', as: :two_factor_confirm_disable
    post 'disable/link-email',             to: 'two_factor#send_disable_email', as: :two_factor_send_disable_email
    get  'disable/link/:token',            to: 'two_factor#disable_link', as: :two_factor_disable_link
    post 'disable/link',                   to: 'two_factor#confirm_disable_link', as: :two_factor_confirm_disable_link
    post 'backup',                         to: 'two_factor#show_backup_code', as: :two_factor_backup_code
  end

  scope  'users' do
    root                                to: 'users#index', as: :users
    get    '/stack-redirect',           to: 'users#stack_redirect', as: :stack_redirect
    post   '/claim-content',            to: 'users#transfer_se_content', as: :claim_stack_content
    get    '/mobile-login',             to: 'users#qr_login_code', as: :qr_login_code
    get    '/mobile-login/:token',      to: 'users#do_qr_login', as: :qr_login
    get    '/me',                       to: 'users#me', as: :users_me
    get    '/me/preferences',           to: 'users#preferences', as: :user_preferences
    post   '/me/preferences',           to: 'users#set_preference', as: :set_user_preference
    get    '/me/filters',               to: 'users#filters', as: :user_filters
    get    '/me/filters/default/',      to: 'users#default_filter', as: :default_filter
    post   '/me/filters',               to: 'users#set_filter', as: :set_user_filter
    delete '/me/filters',               to: 'users#delete_filter', as: :delete_user_filter
    get    '/me/notifications',         to: 'notifications#index', as: :notifications
    get    '/edit/profile',             to: 'users#edit_profile', as: :edit_user_profile
    patch  '/edit/profile',             to: 'users#update_profile', as: :update_user_profile
    get    '/me/vote-summary',          to: 'users#my_vote_summary', as: :my_vote_summary
    get    '/avatar/:letter/:color/:size', to: 'users#specific_avatar', as: :specific_auto_avatar
    get    '/disconnect-sso',           to: 'users#disconnect_sso', as: :user_disconnect_sso
    post   '/disconnect-sso',           to: 'users#confirm_disconnect_sso', as: :user_confirm_disconnect_sso
    get    '/:id',                      to: 'users#show', as: :user
    get    '/:id/flags',                to: 'flags#history', as: :flag_history
    get    '/:id/activity',             to: 'users#activity', as: :user_activity
    get    '/:id/mod',                  to: 'users#mod', as: :mod_user
    get    '/:id/posts',                to: 'users#posts', as: :user_posts
    get    '/:id/vote-summary',         to: 'users#vote_summary', as: :vote_summary
    get    '/:id/mod/privileges',       to: 'users#mod_privileges', as: :user_privileges
    post   '/:id/mod/privileges',       to: 'users#mod_privilege_action', as: :user_privilege_action
    post   '/:id/mod/toggle-role',      to: 'users#role_toggle', as: :toggle_user_role
    get    '/:id/mod/annotations',      to: 'users#annotations', as: :user_annotations
    post   '/:id/mod/annotations',      to: 'users#annotate', as: :annotate_user
    get    '/:id/mod/activity-log',     to: 'users#full_log', as: :full_user_log
    post   '/:id/hellban',              to: 'admin#hellban', as: :hellban_user
    get    '/:id/avatar/:size',         to: 'users#avatar', as: :user_auto_avatar
  end

  post   'notifications/:id/read',         to: 'notifications#read', as: :read_notifications
  post   'notifications/read_all',         to: 'notifications#read_all', as: :read_all_notifications

  post   'votes/new',                      to: 'votes#create', as: :create_vote
  delete 'votes/:id',                      to: 'votes#destroy', as: :destroy_vote

  post   'answers/:id/convert',            to: 'answers#convert_to_comment', as: :convert_to_comment

  post   'flags/new',                      to: 'flags#new', as: :new_flag

  scope 'comments' do
    post   'new',                          to: 'comments#create_thread', as: :create_comment_thread
    get    'thread/:id/pingable',          to: 'comments#pingable', as: :thread_pingable
    post   'thread/:id/new',               to: 'comments#create', as: :create_comment
    post   'thread/:id/rename',            to: 'comments#thread_rename', as: :rename_comment_thread
    post   'thread/:id/restrict',          to: 'comments#thread_restrict', as: :restrict_comment_thread
    post   'thread/:id/unrestrict',        to: 'comments#thread_unrestrict', as: :unrestrict_comment_thread
    get    'thread/:id/followers',         to: 'comments#thread_followers', as: :comment_thread_followers
    get    'post/:post_id',                to: 'comments#post', as: :post_comments
    post   'post/:post_id/follow',         to: 'comments#post_follow', as: :follow_post_comments
    get    ':id',                          to: 'comments#show', as: :comment
    get    'thread/:id',                   to: 'comments#thread', as: :comment_thread
    post   ':id/edit',                     to: 'comments#update', as: :update_comment
    delete ':id/delete',                   to: 'comments#destroy', as: :delete_comment
    patch  ':id/delete',                   to: 'comments#undelete', as: :undelete_comment
  end

  get    'subscriptions/new/:type',        to: 'subscriptions#new', as: :new_subscription
  post   'subscriptions/new',              to: 'subscriptions#create', as: :create_subscription
  get    'subscriptions',                  to: 'subscriptions#index', as: :subscriptions
  post   'subscriptions/:id/enable',       to: 'subscriptions#enable', as: :enable_subscription
  delete 'subscriptions/:id',              to: 'subscriptions#destroy', as: :destroy_subscription

  scope 'reports' do
    root                                   to: 'reports#users', as: :users_report
    get    'subscriptions',                to: 'reports#subscriptions', as: :subscriptions_report
    get    'posts',                        to: 'reports#posts', as: :posts_report
    get    'reactions',                    to: 'reports#reactions', as: :reactions_report
  end

  get    'help',                           to: 'posts#help_center', as: :help_center

  scope 'categories' do
    root                                   to: 'categories#index', as: :categories
    get    'new',                          to: 'categories#new', as: :new_category
    post   'new',                          to: 'categories#create', as: :create_category
    post   ':id/filters/default',          to: 'categories#default_filter', as: :set_default_filter
    get    ':id',                          to: 'categories#show', as: :category
    get    ':id/edit',                     to: 'categories#edit', as: :edit_category
    post   ':id/edit',                     to: 'categories#update', as: :update_category
    get    ':id/edit/post-types',          to: 'categories#category_post_types', as: :edit_category_post_types
    post   ':id/edit/post-types',          to: 'categories#update_cat_post_type', as: :update_category_post_types
    delete ':id/edit/post-types',          to: 'categories#delete_cat_post_type', as: :destroy_category_post_type
    delete ':id',                          to: 'categories#destroy', as: :destroy_category
    get    ':id/types',                    to: 'categories#post_types', as: :category_post_types
    get    ':id/feed',                     to: 'categories#rss_feed', as: :category_feed
    get    ':id/tags',                     to: 'tags#category', as: :category_tags
    get    ':id/tags/new',                 to: 'tags#new', as: :new_tag
    post   ':id/tags/new',                 to: 'tags#create', as: :create_tag
    get    ':id/tags/:tag_id',             to: 'tags#show', as: :tag
    get    ':id/tags/:tag_id/children',    to: 'tags#children', as: :tag_children
    get    ':id/tags/:tag_id/edit',        to: 'tags#edit', as: :edit_tag
    patch  ':id/tags/:tag_id/edit',        to: 'tags#update', as: :update_tag
    post   ':id/tags/:tag_id/rename',      to: 'tags#rename', as: :rename_tag
    get    ':id/tags/:tag_id/merge',       to: 'tags#select_merge', as: :select_tag_merge
    post   ':id/tags/:tag_id/merge',       to: 'tags#merge', as: :merge_tag
    get    ':id/tags/:tag_id/nuke',        to: 'tags#nuke_warning', as: :nuke_tag_warning
    delete ':id/tags/:tag_id/nuke',        to: 'tags#nuke', as: :nuke_tag
    get    ':category/suggested-edits',    to: 'suggested_edit#category_index', as: :suggested_edits_queue
  end

  get   'warning',                         to: 'mod_warning#current', as: :current_mod_warning
  post  'warning/approve',                 to: 'mod_warning#approve', as: :current_mod_warning_approve
  get   'warning/log/:user_id',            to: 'mod_warning#log', as: :mod_warning_log
  get   'warning/new/:user_id',            to: 'mod_warning#new', as: :new_mod_warning
  post  'warning/new/:user_id',            to: 'mod_warning#create', as: :create_mod_warning
  post  'warning/lift/:user_id',            to: 'mod_warning#lift', as: :lift_mod_warning

  get   'uploads/:key',                    to: 'application#upload', as: :uploaded

  scope 'dashboard' do
    root                                   to: 'application#dashboard', as: :dashboard
    get 'reports',                         to: 'reports#users_global', as: :global_users_report
    get 'reports/subscriptions',           to: 'reports#subs_global', as: :global_subs_report
    get 'reports/posts',                   to: 'reports#posts_global', as: :global_posts_report
  end

  scope 'ca' do
    root                                   to: 'advertisement#index', as: :ads
    get 'codidact.png',                    to: 'advertisement#codidact', as: :codidact_ads
    get 'community.png',                   to: 'advertisement#community', as: :community_ads
    get 'posts/random.png',                to: 'advertisement#random_question', as: :random_question_ads
    get 'posts/promoted.png',              to: 'advertisement#promoted_post', as: :promoted_post_ads
    get 'posts/:id.png',                   to: 'advertisement#specific_question', as: :specific_question_ads
    get 'category/:id.png',                to: 'advertisement#specific_category', as: :specific_category_ads
  end

  scope 'tour' do
    root                                   to: 'tour#index', as: :tour
    get 'q',                               to: 'tour#question1', as: :tour_q1
    get 'ask',                             to: 'tour#question2', as: :tour_q2
    get 'qa',                              to: 'tour#question3', as: :tour_q3
    get 'more',                            to: 'tour#more', as: :tour_more
    get 'end',                             to: 'tour#end', as: :tour_end
  end

  scope 'abilities' do
    root                                   to: 'abilities#index', as: :abilities
    get 'recalc',                          to: 'abilities#recalc', as: :abilities_recalc
    get ':id',                             to: 'abilities#show', as: :ability
  end

  scope 'donate' do
    root                                   to: 'donations#index', as: :donate
    post 'intent',                         to: 'donations#intent', as: :donation_intent
    post 'success',                        to: 'donations#success', as: :donation_success
    post 'callback',                       to: 'donations#callback', as: :donation_callback
  end

  scope 'oauth' do
    root                                   to: 'micro_auth/authentication#initiate', as: :initiate_oauth
    post   'approve',                      to: 'micro_auth/authentication#approve', as: :approve_oauth
    get    'reject',                       to: 'micro_auth/authentication#reject', as: :reject_oauth
    post   'token',                        to: 'micro_auth/authentication#token', as: :oauth_token

    scope 'apps' do
      root                                 to: 'micro_auth/apps#index', as: :oauth_apps
      get    'new',                        to: 'micro_auth/apps#new', as: :new_oauth_app
      post   'new',                        to: 'micro_auth/apps#create', as: :create_oauth_app
      get    ':id',                        to: 'micro_auth/apps#show', as: :oauth_app
      get    ':id/edit',                   to: 'micro_auth/apps#edit', as: :edit_oauth_app
      post   ':id/edit',                   to: 'micro_auth/apps#update', as: :update_oauth_app
      post   ':id/deactivate',             to: 'micro_auth/apps#deactivate', as: :deactivate_oauth_app
    end
  end

  get   '403',                             to: 'errors#forbidden'
  get   '404',                             to: 'errors#not_found'
  get   '409',                             to: 'errors#conflict'
  get   '418',                             to: 'errors#stat'
  get   '422',                             to: 'errors#unprocessable_entity'
  get   '423',                             to: 'errors#read_only'
  get   '500',                             to: 'errors#internal_server_error'

  get   'osd',                             to: 'application#osd', as: :osd

  scope 'network' do
    root                                   to: 'fake_community#communities', as: :fc_communities
  end

  # Communities can have custom js or css defined (placed in public/assets/community).
  # If these are not defined for a community, respond with 204 (ok but empty)
  get '/assets/community/*path', to: ->(env) { [204, {}, ['']] }
end
