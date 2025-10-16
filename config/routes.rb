TheMechanic2::Engine.routes.draw do
  root to: 'the_mechanic_2/benchmarks#index'
  
  post 'validate', to: 'the_mechanic_2/benchmarks#validate'
  post 'run', to: 'the_mechanic_2/benchmarks#run'
  post 'export', to: 'the_mechanic_2/benchmarks#export'
end
