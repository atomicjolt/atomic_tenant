
module AtomicTenant
  module Exceptions

    class UnableToLinkDeploymentError < StandardError
    end

    class NonUniqueAdminApp < StandardError; end
    class NoAdminApp < StandardError; end
  end
end