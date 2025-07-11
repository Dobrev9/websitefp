Rails.application.routes.draw do
  # Health check and root
  root "pages#home"
  get "home", to: "pages#home"
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  get "login", to: "pages#login"
  post "login", to: "pages#authenticate"
  delete "logout", to: "pages#logout"

  # Protected content route
  get "class-materials", to: "pages#protected_content", as: "protected_content"
  get "protected_content", to: "pages#protected_content"

  # Edit home text routes
  get "edit_home_text", to: "pages#edit_home_text"
  patch "update_home_text", to: "pages#update_home_text"

  # File upload and management routes
  get "upload_files", to: "files#upload"
  post "upload_files", to: "files#upload_files"
  post "create_folder", to: "files#create_folder"
  post "sync_local_files", to: "files#sync_local_files"

  # File deletion routes (fixed syntax)
  delete "/files/:filename", to: "files#destroy", as: "delete_file_by_path"
  delete "/delete_file/:filename", to: "files#delete_file", as: "delete_file"
  delete "/delete_folder/:folder_name", to: "files#delete_folder", as: "delete_folder"

  # Khôlle schedule routes (removed duplicate)
  get "kholle_schedule", to: "pages#kholle_schedule"
  post "kholle_schedule", to: "pages#kholle_schedule"

  # Uncomment these when you're ready for PWA
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
