require 'uri'

module AtomicTenant
  module DeploymentManager
      class PlatformGuidStrategy < DeploymentManagerStrategy
          def name
            "PlatformGuidStrategy"
          end

          def call(id_token:)
            decoded_token = JWT.decode(id_token, nil, false)

            platform_guid = decoded_token.dig(0, AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, "guid")
            target_link_uri = decoded_token.dig(0, AtomicLti::Definitions::TARGET_LINK_URI_CLAIM)


            return DeploymentStrategyResult.new() if !platform_guid.present? || !target_link_uri.present?


            uri = URI.parse(target_link_uri)
            application_key = uri.host&.split('.')&.first

            return DeploymentStrategyResult.new() if !application_key.present?

            app = Application.find_by(key: application_key)

            return DeploymentStrategyResult.new() if !app.present?

            if(pinned = AtomicTenant::PinnedPlatformGuid.find_by(platform_guid: platform_guid, application_id: app.id))
              DeploymentStrategyResult.new(application_instance_id: pinned.application_instance_id)
            else
              DeploymentStrategyResult.new()
            end
          end
      end
  end
end