module AtomicTenant
  class Engine < ::Rails::Engine
    isolate_namespace AtomicTenant
  end
end
