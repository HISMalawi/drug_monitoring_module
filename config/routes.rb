DrugMonitoringProgram::Application.routes.draw do

  get "administration/index"

  get "administration/add_site"

  get "administration/edit_site"

  get "administration/list_sites"

  post "administration/save_site"

  post "administration/delete_site"

  get '/map' => "administration#map"
  
  post "administration/save_notice_changes"
  ################### USER ##############################
  match '/login' => "user#login"

  match '/logout' => "user#logout"

  match '/verify_user' => "user#verify_user"

  match '/new_user' => "user#create"

  match '/check_username' => "user#check_username"

  get "user/index"

  get "user/login"

  get "user/logout"

  get "user/create"

  get "user/edit"

  get "user/edit_user"

  post "user/verify_user"

  post "user/check_username"

  post "user/save"

  post "user/delete"

  post "user/save_edit"


  ################### OBSERVATION ######################

  ################### REPORT ############################
  get "report/index"
  get "report/site_list"
  get "report/report_menu"
  get "report/drug_report"
  get "report/drug_utilization_report"
  get "report/site_report"
  get "report/aggregate_report"
  post "report/process_report"
  get "report/stock_out_estimates"
  get "report/months_of_stock"
  get "report/months_of_stock_main"
  get "report/stock_movement"
  get "report/delivery_report"
  get "report/update_display_units"
  post "report/delivery_report"
  get "report/physical_stock_summary"
  get "report/notices"
  post "report/notices"
  post "report/physical_stock_summary"
  post "report/update_notice"
  match 'report/:id' => 'report#menu', :as => :report
  match '/months_of_stock_main' => "report#months_of_stock_main"
  match '/stock_report' => "report#stock_report"
  match '/get_stock_report' => "report#get_stock_report"
  ################### HOME ##############################

  match '/home' => "home#index"
  match '/map_main' => "home#map_main"
  get "home/index"
  get '/dashboard' => "home#dashboard"
  get "home/notices"
  get "home/map_main"
  get "home/overstock"
  get "home/low_stock"
  post "home/graph"
  get '/ajax_burdens' => "home#ajax_burdens"
  get '/ajax_low_stock' => "home#ajax_low_stock"
  get '/ajax_high_stock' => "home#ajax_high_stock"
  get "home/manage_notices"
  get '/get_couch_changes' => "home#get_couch_changes"
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

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "home#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
