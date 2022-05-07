Rails.application.routes.draw do
  mount AtomicTenant::Engine => '/atomic_tenant'
end
