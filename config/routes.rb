Intermix::Application.routes.draw do
  
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
    end

    resources :templates do
      get :search, :on => :collection
    end

    match 'admin' => 'admin#index'
    match '/' => 'admin#index'

  end

  #match 'admin' => 'admin/admin#index'
  #match 'admin/:controller(/:action(/:id))', :controller => /admin\/[^\/]+/

  mount Ckeditor::Engine => "/ckeditor"

  match '/participants/auth/:provider/callback' => 'authentications#create'
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
      put :dialog_settings_save
      post :apply_dialog
      post :add_moderator
      get :group_participant_edit
      put :group_participant_save
      get :get_default
      get :get_dg_default
      get :test_template
    end
  end 
  
  resources :dialogs do
    member do
      get :view
      get :edit
      get :new
      get :forum
      get :meta
      get :result
      get :period_edit
      post :period_save
      put :period_save
      get :group_settings
      put :group_settings_save
      get :get_default
      get :test_template
    end
  end 
  match 'voting_results' => 'dialogs#results'
  
  resources :group_participants
  
  resources :items do
    get :rate, :on => :member
    get :get_summary, :on => :member
    get :play, :on => :member
    get :view, :on => :member
    get :thread, :on => :member
    get :pubgallery, :on => :collection
  end  
  
  resources :messages do
    get :list, :on => :collection
  end  
  
    
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
  
  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  match 'privacy' => 'front#privacy'
  match 'optout' => 'front#optout'
  match 'optout_confirm' => 'front#optout_confirm'
  match 'front/getadmin1s' => 'front#getadmin1s'
  match 'front/getadmin2s' => 'front#getadmin2s'
  match 'front/getmetro' => 'front#getmetro'
  match 'front/setsess' => 'front#setsess'
  match 'front/test' => 'front#test'
  match 'helptext(/:code)', :controller=>:front, :action=>:helptext

  match 'front/instantjointest', :controller=>:front, :action=>:instantjointest
  match 'front/instantjoinform', :controller=>:front, :action=>:instantjoinform
  match 'front/instantjoin', :controller=>:front, :action=>:instantjoin

  match 'front/dialog', :controller=>:front, :action=>:dialog
  match 'front/dialogjoinform', :controller=>:front, :action=>:dialogjoinform
  match 'front/dialogjoin', :controller=>:front, :action=>:dialogjoin
  match 'djoin', :controller=>:front, :action=>:dialogjoinform
  match 'front/group', :controller=>:front, :action=>:group
  match 'front/groupjoinform', :controller=>:front, :action=>:groupjoinform
  match 'front/groupjoin', :controller=>:front, :action=>:groupjoin
  match 'gjoin', :controller=>:front, :action=>:groupjoinform
  match 'join', :controller=>:front, :action=>:joinform
  match 'front/join', :controller=>:front, :action=>:join
  match 'youarehere', :controller=>:front, :action=>:youarehere
  
  match 'front/confirm', :controller=>:front, :action=>:confirm
  match 'autologin', :controller=>:front, :action=>:autologin
  match 'front/notconfirmed', :controller=>:front, :action=>:notconfirmed
  
  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"
  root :to => 'front#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  #match ':controller(/:action(/:id(.:format)))'
  
  match 'forum(/:action(/:id(.:format)))', :controller=>:forum
  match 'people(/:action(/:id(.:format)))', :controller=>:people
  
  match 'participant/:id/profile', :controller=>:people, :action=>:profile
  match 'participant/:id/wall', :controller=>:wall, :action=>:index
  match 'participant/:id/photos', :controller=>:front, :action=>:photos
  
  match 'profile', :controller=>:people, :action=>:profile
  match 'photos', :controller=>:front, :action=>:photos
  
  match 'me/profile' => 'profiles#index'
  match 'me/profile/edit' => 'profiles#edit'
  match 'me/profile/settings' => 'profiles#settings'
  match 'me/profile/update' => 'profiles#update'
  match 'me/wall' => 'wall#index'
  match 'me/photos' => 'profiles#photos'
  match 'me/photolist' => 'profiles#photolist'
  match 'me/picupload' => 'profiles#picupload'
  match 'me/picdelete' => 'profiles#picdelete'
  match 'me/twitauth' => 'profiles#twitauth'
  match 'me/twitcallback' => 'profiles#twitcallback'
  match 'me/friends' => 'people#friends'
  
  match 'fbapp(/:action)', :controller=>:fbapp
  
  match 'helppage/:code', :controller=>:front, :action=>:helppage
  
  match 'pixel/:id.gif', :to => 'front#pixel'
    
end
