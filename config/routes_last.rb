Brpm::Application.routes.draw do
  # this must be the last and final catch all for the routes
  # file as it will cartch anything not matched and show a 404 error page
  match '*path' => 'sessions#bad_route'
end
