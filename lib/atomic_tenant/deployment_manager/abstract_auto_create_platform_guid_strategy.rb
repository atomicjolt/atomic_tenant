require 'uri'

module AtomicTenant
  module DeploymentManager
    class AbstractAutoCreatePlatformGuidStrategy < DeploymentManagerStrategy
      TRUSTED_ISSUERS = [
        %r|^https://canvas\.instructure\.com$|,
        %r|^https://[a-z0-9.-]+\.brightspace\.com$|,
        %r|^https://blackboard\.com$|,
      ].freeze

      def name
        raise NotImplementedError, "Subclasses must implement #name"
      end

      def call(decoded_id_token:)
        issuer = decoded_id_token["iss"]
        platform_guid = decoded_id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, "guid")
        target_link_uri = decoded_id_token[AtomicLti::Definitions::TARGET_LINK_URI_CLAIM]

        if !platform_guid.present? || !target_link_uri.present?
          return AtomicTenant::DeploymentManager::DeploymentStrategyResult.new()
        end

        uri = URI.parse(target_link_uri)
        application_key = uri.host&.split('.')&.first
        return AtomicTenant::DeploymentManager::DeploymentStrategyResult.new() if !application_key.present?

        app = Application.find_by(key: application_key)
        return AtomicTenant::DeploymentManager::DeploymentStrategyResult.new() if app.nil?

        if !TRUSTED_ISSUERS.any? { |pattern| issuer.match?(pattern) }
          existing_app_instance_count = AtomicTenant::LtiDeployment
            .joins(:application_instance)
            .where(
              iss: issuer,
              application_instances: { application_id: app.id },
            ).distinct.count(:application_instance_id)

          if existing_app_instance_count >= AtomicTenant.untrusted_iss_tenant_limit
            raise AtomicTenant::Exceptions::OnboardingException, "The issuer #{issuer} has reached the limit of #{AtomicTenant.untrusted_iss_tenant_limit} unique tenants for the application #{application_key}."
          end
        end

        site_url = extract_site_url(decoded_id_token)

        app_inst = find_application_instance(app, site_url, issuer, platform_guid)
        app_inst ||= maybe_create_application_instance(app, site_url, issuer, platform_guid)
        pin = pin_platform_guid(issuer, platform_guid, app.id, app_inst.id)
        AtomicTenant::DeploymentManager::DeploymentStrategyResult.new(application_instance_id: pin.application_instance_id)
      end

      private

      def find_application_instance(current_application, site_url, issuer, platform_guid)
        raise NotImplementedError, "Subclasses must implement #find_application_instance"
      end

      def create_application_instance(app, site_url, issuer, platform_guid)
        raise NotImplementedError, "Subclasses must implement #create_application_instance"
      end

      def maybe_create_application_instance(app, site_url, issuer, platform_guid)
        ActiveRecord::Base.transaction do
          create_application_instance(app, site_url, issuer, platform_guid)
        rescue ActiveRecord::RecordNotUnique
          # If we get a RecordNotUnique error, it means another process created the instance concurrently.
          find_application_instance(app, site_url, issuer, platform_guid)
        end
      end

      # Pin platform guid, handling concurrent launches both trying to pin the same
      # platform guid at the same time.
      def pin_platform_guid(iss, platform_guid, application_id, application_instance_id)
        begin
          AtomicTenant::PinnedPlatformGuid.create!(
            iss:,
            platform_guid:,
            application_id:,
            application_instance_id:,
          )
        rescue ActiveRecord::RecordNotUnique
          AtomicTenant::PinnedPlatformGuid.find_by!(
            iss:,
            platform_guid:,
            application_id:,
            application_instance_id:,
          )
        end
      end

      def extract_site_url(decoded_id_token)
        platform_claim = decoded_id_token[AtomicLti::Definitions::TOOL_PLATFORM_CLAIM]
        product_family_code = platform_claim["product_family_code"]

        if product_family_code == "canvas"
          canvas_domain = decoded_id_token.dig(AtomicLti::Definitions::CUSTOM_CLAIM, "canvas_api_domain")
          if canvas_domain.blank?
            raise AtomicTenant::Exceptions::OnboardingException, "Missing canvas_api_domain claim from canvas launch"
          end

          ensure_https(canvas_domain)
        elsif product_family_code == "BlackboardLearn"
          blackboard_url = platform_claim["url"]

          if blackboard_url.blank?
            raise AtomicTenant::Exceptions::OnboardingException, "Missing url in platform claim from blackboard launch"
          end

          ensure_https(blackboard_url)
        else
          decoded_id_token["iss"]
        end
      end

      def ensure_https(url)
        return nil if url.blank?

        url = "https://#{url}" unless url.start_with?("http")
        url.gsub("http://", "https://")
      end
    end
  end
end
