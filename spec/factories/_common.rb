FactoryBot.define do
  sequence :key do |n|
    "key_#{n}"
  end

  sequence :lti_key do |n|
    "lti_key_#{n}"
  end

  sequence :iss do |n|
    "http://#{n}.example.com"
  end

  sequence :deployment_id do |n|
    "deployment_id_#{n}"
  end

  sequence :client_id do |n|
    "client_id_#{n}"
  end

  sequence :platform_guid do |n|
    "platform_guid_#{n}"
  end
end
