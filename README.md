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

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
