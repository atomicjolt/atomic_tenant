FactoryBot.define do
  factory :atomic_tenant_lti_deployment, class: 'AtomicTenant::LtiDeployment' do
    iss
    deployment_id
    association :application_instance
  end

  factory :atomic_tenant_pinned_client_id, class: 'AtomicTenant::PinnedClientId' do
    iss
    client_id
    association :application_instance
  end

  factory :atomic_tenant_pinned_platform_guid, class: 'AtomicTenant::PinnedPlatformGuid' do
    iss
    platform_guid
    association :application
    application_instance { association :application_instance, application: application }
  end

  factory :application_instance do
    association :application
    lti_key
  end

  factory :application do
    key
  end
end
