Rails.application.routes.draw do
  # Mount the TheMechanic2 engine
  mount TheMechanic2::Engine => "/mechanic"
  
  # Root route
  root to: proc { [200, {}, ["Rails app running. Visit /mechanic to access TheMechanic2"]] }
end
