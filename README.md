# AtomicTenant
This gem handles figuring out which tenant is being used and adds that information .

## Installation
Add this line to your application's Gemfile:

```ruby
gem "atomic_tenant"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install atomic_tenant
```

Then install the migrations:
./bin/rails atomic_tenant:install:migrations

## Usage
Create a new initializer:
```
  config/initializers/atomic_tenant.rb
```

With the following content:
```
  AtomicTenant.jwt_secret = Rails.application.secrets.auth0_client_secret
  AtomicTenant.jwt_aud = Rails.application.secrets.auth0_client_id
  AtomicTenant.admin_subdomain = "admin".freeze
```

### Row Level Security Tenanting
This gem also includes modules and helpers for a row level security tenanting solution.

Configure the settings in the initializer:

```ruby
  AtomicTenant.tenants_table = :tenants
  AtomicTenant.db_tenant_restricted_user = Rails.application.credentials.db_tenant_restricted_user
```

This example configures AtomicTenant to use the Tenant model as the tenants table, and will expect tenanted models to have a `tenant_id` field on them. db_tenant_restricted_user is the database user that will have row level security enforced.

Add row level security to each tenanted table in a migration:

```ruby
  dir.up do
    # Enable row level security and add row level security policies for the users table
    AtomicTenant::RowLevelSecurity.add_row_level_security(:users)
  end
  dir.down do
    # Remove row level security and remove row level security policies for the users table
    AtomicTenant::RowLevelSecurity.remove_row_level_security(:users)
  end
```

#### Tenantable
Include the `AtomicTenant::Tenantable` module in your base model to default all models private:
```ruby
class ApplicationRecord < ActiveRecord::Base
  include AtomicTenant::Tenantable
end
```

If you default all models to private, non tenanted models can be marked public with `set_public_tenanted`:
```ruby
class Tenant < ApplicationRecord
  set_public_tenanted
end
```

Alternatively you can include `AtomicTenant::Tenantable` in just the models you want to be tenanted.

There is a helper to verify that row level security is set on a model. If you default all models private, it's a good idea to have a test that verifies that all private models do actually have row level security enabled on them:
```ruby
require "rails_helper"

RSpec.describe Tenant do
  describe "private models have row level security enabled" do
    it "ensures row level security is enabled for private tenanted models" do
      Rails.application.eager_load!
      private_models = AtomicTenant::Tenantable.private_tenanted_models.map(&:table_name)
      expect(private_models).not_to be_empty

      AtomicTenant::Tenantable.private_tenanted_models.each do |model|
        expect do
          AtomicTenant::Tenantable.verify_tenanted(model)
        end.not_to raise_error
      end
    end
  end
end
```

#### TenantSwitching
To use `TenantSwitching`, include the module in your tenant model:
```ruby
class Tenant < ApplicationRecord
  set_public_tenanted
  include AtomicTenant::TenantSwitching
end
```

The `Tenant` model must have a key field.

Switching tenants can then be done via Apartment-esque tenant switching methods:
  1. ```ruby
      Tenant.switch!(Tenant.find_by(key: "admin"))
      ```
  2. ```ruby
      Tenant.switch(Tenant.find_by(key: "admin")) do
        Tenant.current_key
      end
      # => "admin"

      Tenant.current_key
      # => "public"
      ```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
