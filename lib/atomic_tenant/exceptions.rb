
module AtomicTenant
  module Exceptions

    class UnableToLinkDeploymentError < StandardError
    end

    class NonUniqueAdminApp < StandardError; end
    class NoAdminApp < StandardError; end
    class InvalidTenantKeyError < StandardError; end
    class TenantNotFoundError < StandardError; end
    class TenantNotSet < StandardError; end
    class OnboardingException < StandardError; end
  end
end
