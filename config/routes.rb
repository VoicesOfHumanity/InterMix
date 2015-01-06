Rails.application.routes.draw do
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

    resources :hubs do
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

  get '/participants/auth/:provider/callback' => 'authentications#create'
  post '/participants/auth/:provider/callback' => 'authentications#create'
  resources :authentications

  #devise_for :participants, :controllers => { :omniauth_callbacks => "omniauth_callbacks" }
  devise_for :participants, :controllers => {:registrations => 'registrations'}
  resources :participants do
    get :search, :on => :collection
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
      get :period_edit
      post :period_save
      put :period_save
      get :group_settings
      put :group_settings_save
      get :get_default
      get :test_template
      get :get_period_default
      get :test_period_template
      post :set_show_previous
      get :show_latest
    end
  end 
  get 'voting_results' => 'dialogs#results'
  
  resources :group_participants do
    get :remove, :on => :member
  end
  
  resources :items do
    get :rate, :on => :member
    get :get_summary, :on => :member
    get :play, :on => :member
    get :view, :on => :member
    get :thread, :on => :member
    get :pubgallery, :on => :collection
    get :list_comments_simple, :on => :member
    get :geoslider, :on => :collection
    get :geoslider_update, :on => :collection
  end  
  
  resources :messages do
    get :list, :on => :collection
  end  
  
  get 'privacy' => 'front#privacy'
  get 'optout' => 'front#optout'
  get 'optout_confirm' => 'front#optout_confirm'
  get 'front/getadmin1s' => 'front#getadmin1s'
  get 'front/getadmin2s' => 'front#getadmin2s'
  get 'front/getmetro' => 'front#getmetro'
  get 'front/setsess' => 'front#setsess'
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
  post 'front/fbjoinfinal', :controller=>:front, :action=>:fbjoinfinal
  post 'front/fbjoin', :controller=>:front, :action=>:fbjoin
  get 'youarehere', :controller=>:front, :action=>:youarehere
  
  get 'front/confirm', :controller=>:front, :action=>:confirm
  get 'autologin', :controller=>:front, :action=>:autologin
  get 'front/notconfirmed', :controller=>:front, :action=>:notconfirmed

  get 'forum(/:action(/:id(.:format)))', :controller=>:forum
  get 'people(/:action(/:id(.:format)))', :controller=>:people
  
  get 'participant/:id/profile', :controller=>:people, :action=>:profile
  get 'participant/:id/wall', :controller=>:wall, :action=>:index
  get 'participant/:id/photos', :controller=>:front, :action=>:photos
  
  get 'profile', :controller=>:people, :action=>:profile
  get 'photos', :controller=>:front, :action=>:photos
  
  get 'me/profile' => 'profiles#index'
  get 'me/profile/edit' => 'profiles#edit'
  get 'me/profile/meta' => 'profiles#missingmeta'
  get 'me/profile/settings' => 'profiles#settings'
  post 'me/profile/update' => 'profiles#update'
  get 'me/wall' => 'wall#index'
  get 'me/photos' => 'profiles#photos'
  get 'me/photolist' => 'profiles#photolist'
  get 'me/picupload' => 'profiles#picupload'
  post 'me/picdelete' => 'profiles#picdelete'
  get 'me/twitauth' => 'profiles#twitauth'
  get 'me/twitcallback' => 'profiles#twitcallback'
  get 'me/friends' => 'people#friends'
  
  get 'fbapp(/:action)', :controller=>:fbapp
  
  get 'helppage/:code', :controller=>:front, :action=>:helppage
  
  get 'pixel/:id.gif', :to => 'front#pixel'
    
  root 'front#index'
  
  
end
