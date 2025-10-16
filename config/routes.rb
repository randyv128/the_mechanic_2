TheMechanic2::Engine.routes.draw do
  root to: 'benchmarks#index'
  
  post 'validate', to: 'benchmarks#validate'
  post 'run', to: 'benchmarks#run'
  post 'export', to: 'benchmarks#export'
end
