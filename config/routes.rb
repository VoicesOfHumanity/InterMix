Rails.application.routes.draw do
  resources :moons
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  
  mount Ckeditor::Engine => '/ckeditor'

  get "messages/index"
  get "messages/new"
  get "messages/edit"
  get "messages/create"
  get "messages/update"

  namespace "admin" do
    
    resources :ratings
  
    resources :group_participants
    
    resources :items do
      get :search, :on => :collection
    end  

    resources :complaints do
      get :search, :on => :collection
    end

    resources :communities do
      get :search, :on => :collection
      get :admins, :on => :member
      post :admin_add, :on => :member
      delete :admin_del, :on => :member
    end

    resources :conversations do
      get :search, on: :collection
      get :communities, on: :member
      post :community_add, :on => :member
      delete :community_del, :on => :member
    end

    resources :networks do
      get :search, :on => :collection
      get :communities, on: :member
      post :community_add, :on => :member
      delete :community_del, :on => :member
    end
    
    resources :hubs do
      get :search, :on => :collection
      get :admins, :on => :member
      post :admin_add, :on => :member
      delete :admin_del, :on => :member
    end

    resources :religions do
      get :search, :on => :collection
    end

    resources :moons do
      get :search, :on => :collection
      get :admins, :on => :member
      post :admin_add, :on => :member
      delete :admin_del, :on => :member
    end
    
    resources :help_texts do
      get :search, :on => :collection
    end

    resources :dialogs do
      get :search, :on => :collection
      get :admins, :on => :member
      post :admin_add, :on => :member
      delete :admin_del, :on => :member
      get :groups, :on => :member
      post :group_add, :on => :member
      delete :group_del, :on => :member
    end

    resources :groups do
      get :search, :on => :collection
      get :member_list, :on => :collection
      get :dialogs, :on => :member
    end  

    resources :metamaps do
      get :search, :on => :collection
      get :nodes, :on => :member
      post :node_add, :on => :member
      delete :node_del, :on => :member
      get :node_edit, :on => :member
      get :node_show, :on => :member
      put :node_save, :on => :member
    end

    resources :templates do
      get :search, :on => :collection
    end

    get 'admin' => 'admin#index'
    get '/' => 'admin#index'

  end

  #get 'admin' => 'admin/admin#index'
  #get 'admin/:controller(/:action(/:id))', :controller => /admin\/[^\/]+/

  #mount Ckeditor::Engine => "/ckeditor"

  # well-known protocols for activitypub, etc
  get '.well-known/webfinger', to: 'well_known#webfinger'
  get '.well-known/host-meta', to: 'well_known#hostmeta'
  get '.well-known/nodeinfo', to: 'well_known#nodeinfo'
  
  # activitypub
  post 'u/:acct_id/inbox.json', to: 'activitypub#inbox'
  post 'u/:acct_id/inbox', to: 'activitypub#inbox'
  get 'u/:acct_id', to: 'activitypub#account_info'
  get 'u/:acct_id/feed.json', to: 'activitypub#feed'
  get 'u/:acct_id/key.json', to: 'activitypub#account_key'
  get 'u/:acct_id/following.json', to: 'activitypub#following'
  get 'u/:acct_id/followers.json', to: 'activitypub#followers'
  get 'u/:acct_id/*other', to: 'activitypub#unknown_target'
  post 'u/:acct_id/*other', to: 'activitypub#unknown_target'
  post 'activitypub/follow_account'
  get 'ap/com/:comtag', to: 'activitypub#community_info'
  get 'ap/conv/:tag', to: 'activitypub#conversation_info'
  get 'ap/voh', to: 'activitypub#voh_info'

  get '/participants/auth/:provider/callback' => 'authentications#create'
  post '/participants/auth/:provider/callback' => 'authentications#create'
  get '/participants/visitor_login'
  
  # API for apps
  get 'api/verify_email', to: 'api#verify_email'
  get 'api/login', to: 'api#login'
  get 'api/logout', to: 'api#logout'
  get 'api/register', to: 'api#register'
  post 'api/register', to: 'api#register'
  post 'api/user_from_facebook', to: 'api#user_from_facebook'
  get 'api/get_user', to: 'api#get_user'
  get 'api/update_user', to: 'api#update_user'
  post 'api/update_user', to: 'api#update_user'
  post 'api/update_user_field', to: 'api#update_user_field'
  post 'api/thumbrate', to: 'api#thumbrate'
  post 'api/importance', to: 'api#importance'
  post 'api/report_complaint', to: 'api#report_complaint'
  get 'api/forgot_password', to: 'api#forgot_password'
  post 'api/leave_community', to: 'api#leave_community'
  post 'api/join_community', to: 'api#join_community'

  resources :authentications

  #devise_for :participants, :controllers => { :omniauth_callbacks => "omniauth_callbacks" }
  devise_for :participants, :controllers => {:registrations => 'registrations'}
  resources :participants do
    get :search, :on => :collection
    post :removedata, on: :member
    post :removepersonal, on: :member
  end

  get 'communities/all', to: 'communities#index', action: :index, which: 'all'
  get 'communities/my', to: 'communities#index', action: :index, which: 'my'
  get 'communities/human', to: 'communities#index', action: :index, which: 'human'
  get 'communities/un', to: 'communities#index', action: :index, which: 'un'
  get 'communities/genders', to: 'communities#index', action: :index, which: 'genders'
  get 'communities/generations', to: 'communities#index', action: :index, which: 'generations'
  get 'communities/cities', to: 'communities#index', action: :index, which: 'cities'
  get 'communities/nations', to: 'communities#index', action: :index, which: 'nations'
  get 'communities/religions', to: 'communities#index', action: :index, which: 'religions'
  get 'communities/private', to: 'communities#index', action: :index, which: 'private'
  get 'communities/other', to: 'communities#index', action: :index, which: 'other'
  resources :communities do
    get :index, :on => :collection
    get :members, :on => :member
    get :memlist, :on => :member
    get :admins, :on => :member
    post :admin_add, :on => :member
    delete :admin_del, :on => :member
    get :sublist, :on => :member
    post :sub_add, :on => :member
    delete :sub_del, :on => :member
    post :member_add, :on => :member
    delete :member_del, :on => :member
    get :invite, :on => :member
    post :invitedo, :on => :member
    get :invitejoin, :on => :member
    post :import_member, on: :member
    get :test_template, :on => :member
    get :get_default, :on => :member
    get :join, on: :member
    get :front, on: :member
  end
  #get 'all', on: :collection, to: "communities#index", as: :index
  #get 'my', on: :collection, to: "communities#index", as: :index


  get 'conversations/all', to: 'conversations#index', action: :index, csection: 'all'
  get 'conversations/my', to: 'conversations#index', action: :index, csection: 'my'
  resources :conversations do
    get :change_perspective, on: :member
    get :top_posts, on: :member
    get :test_template, :on => :member
    get :get_default, :on => :member
  end

  get 'networks/all', to: 'networks#index', action: :index, which: 'allnet'
  get 'networks/my', to: 'networks#index', action: :index, which: 'mynet'
  resources :networks do
    get :index, on: :collection
    get :members, on: :member
  end
  
  resources :groups do
    member do
      get :view
      get :edit
      get :new
      get :forum
      get :admin
      get :moderate
      get :members
      get :members_admin
      get :dialogs
      get :subgroups
      get :subgroup_members
      get :subgroup_join
      get :subgroup_unjoin
      post :subgroup_add_to
      post :subgroup_member_addremove
      get :subgroupadd
      post :subgroupsave
      get :invite
      post :invitedo
      get :invitejoin
      get :import
      post :importdo
      get :join
      get :unjoin
      get :period_edit
      post :period_save
      get :subtag_edit
      post :subtag_save
      get :dialog_settings
      patch :dialog_settings_save
      get :remove_dialog
      post :apply_dialog
      post :add_moderator
      get :group_participant_edit
      patch :group_participant_save
      get :get_default
      get :get_dg_default
      get :test_template
      get :twitauth
      get :twitcallback
    end
  end 
  
  resources :dialogs do
    member do
      get :view
      get :forum
      get :meta
      get :result
      get :result_old
      get :previous_result
      get :period_edit
      patch :period_save
      post :period_save
      put :period_save
      get :group_settings
      patch :group_settings_save
      get :get_default
      get :test_template
      get :get_period_default
      get :test_period_template
      post :set_show_previous
      get :show_latest
      get :slider
      get :moons
    end
  end 
  get 'voting_results' => 'dialogs#results'
  
  resources :group_participants do
    get :remove, :on => :member
  end
  
  resources :items do
    get :rate, :on => :member
    post :thumbrate, :on => :member
    post :importancerate, on: :member
    get :get_summary, :on => :member
    get :play, :on => :member
    get :view, :on => :member
    get :thread, :on => :member
    get :pubgallery, :on => :collection
    get :list_comments_simple, :on => :member
    get :geoslider, :on => :collection
    get :geoslider_update, :on => :collection
    post :geoslider_update, :on => :collection
    get :follow, on: :member
    get :unfollow, on: :member
    post :list_api, on: :collection
    get :list_api, on: :collection
    get :item_api, on: :member
    post :report_api, on: :member
    post :create_api, on: :collection
    post :censor, on: :member
    get :followed, on: :collection
  end  
  
  resources :messages do
    get :list, :on => :collection
  end  
  
  get 'privacy' => 'front#privacy'
  get 'optout' => 'front#optout'
  get 'optout_confirm' => 'front#optout_confirm'
  get 'front/getadmin1s' => 'front#getadmin1s'
  get 'front/getadmin2s' => 'front#getadmin2s'
  get 'front/getcities' => 'front#getcities'
  get 'front/getmetro' => 'front#getmetro'
  get 'front/getadmin2_from_city'
  get 'front/getreligions'
  get 'front/getcommunities'
  get 'front/setsess' => 'front#setsess'
  get 'front/updatemoreless' => 'front#updatemoreless'
  get 'front/test' => 'front#test'
  get 'helptext(/:code)', :controller=>:front, :action=>:helptext

  get 'front/instantjointest', :controller=>:front, :action=>:instantjointest
  get 'front/instantjoinform', :controller=>:front, :action=>:instantjoinform
  post 'front/instantjoin', :controller=>:front, :action=>:instantjoin

  get 'front/dialog', :controller=>:front, :action=>:dialog
  get 'front/dialogjoinform', :controller=>:front, :action=>:dialogjoinform
  post 'front/dialogjoin', :controller=>:front, :action=>:dialogjoin
  get 'djoin', :controller=>:front, :action=>:dialogjoinform
  get 'front/group', :controller=>:front, :action=>:group
  get 'front/groupjoinform', :controller=>:front, :action=>:groupjoinform
  post 'front/groupjoin', :controller=>:front, :action=>:groupjoin
  get 'gjoin', :controller=>:front, :action=>:groupjoinform
  get 'join', :controller=>:front, :action=>:joinform
  post 'front/join', :controller=>:front, :action=>:join
  get 'fbjoin', :controller=>:front, :action=>:fbjoinform
  get 'front/fbjoinfinal', :controller=>:front, :action=>:fbjoinfinal
  get 'front/fbjoin', :controller=>:front, :action=>:fbjoin
  post 'front/fbjoin', :controller=>:front, :action=>:fbjoin
  get 'youarehere', :controller=>:front, :action=>:youarehere
  get 'fbjoinlink', controller: :front, action: :fbjoinlink
  get 'front/testajaxjson', controller: :front, action: :testajaxjson
  get 'front/api_fb_login_join', controller: :front, action: :api_fb_login_join
  
  get 'front/confirm', :controller=>:front, :action=>:confirm
  get 'autologin', :controller=>:front, :action=>:autologin
  get 'front/notconfirmed', :controller=>:front, :action=>:notconfirmed

  get 'delete_my_account', :controller=>:front, :action=>:delete_account_screen
  post 'delete_my_account', :controller=>:front, :action=>:delete_account_action

  get 'forum(/:action(/:id(.:format)))', :controller=>:forum
  get 'people(/:action(/:id(.:format)))', :controller=>:people
  get 'people/remote/:remote_actor_id/profile' => 'people#remote_profile'
  get 'people/removed', :controller=>:people, :action=>:removed
  
  get 'participant/:id/profile', :controller=>:people, :action=>:profile
  get 'participant/:id/wall', :controller=>:people, :action=>:wall
  get 'participant/:id/photos', :controller=>:front, :action=>:photos
  get 'participant/:id/messages', :controller=>:messages, :action=>:conversation
  
  get 'profile', :controller=>:people, :action=>:profile
  get 'photos', :controller=>:front, :action=>:photos
  
  get 'me/profile' => 'profiles#index'
  get 'me/profile/edit' => 'profiles#edit'
  get 'me/profile/meta' => 'profiles#missingmeta'
  get 'me/profile/settings' => 'profiles#settings'
  post 'me/profile/update' => 'profiles#update'
  get 'me/profile/password' => 'profiles#password'
  post 'me/profile/update_password' => 'profiles#update_password'  
  get 'me/wall' => 'wall#index'
  get 'me/photos' => 'profiles#photos'
  get 'me/photolist' => 'profiles#photolist'
  post 'me/picupload' => 'profiles#picupload'
  post 'me/picdelete' => 'profiles#picdelete'
  get 'me/twitauth' => 'profiles#twitauth'
  get 'me/twitcallback' => 'profiles#twitcallback'
  get 'me/friends' => 'people#friends'
  get 'me/comtag' => 'profiles#comtag'
  get 'me/invite' => 'profiles#invite'
  post 'me/invitedo' => 'profiles#invitedo'
  
  resources :profiles do
    get :api_get_user_info, on: :member
    post :api_save_user_info, on: :member
  end
  
  get 'fbapp(/:action)', :controller=>:fbapp
  
  get 'helppage/:code', :controller=>:front, :action=>:helppage
  
  get 'pixel/:id.gif', :to => 'front#pixel'
    
  root 'front#index'
  
  get '/conversation/:tagname', to: 'conversations#fronttag'
  get '/community/:tagname', to: 'communities#fronttag'
  get '/:tagname', to: 'communities#fronttag'
  
end
