require "rails_helper"

# Test implementation of the abstract class
class TestAutoCreateStrategy < AtomicTenant::DeploymentManager::AbstractAutoCreatePlatformGuidStrategy
  def name
    "TestAutoCreateStrategy"
  end

  private

  def create_application_instance(app, site_url, issuer, platform_guid)
    # Simple test implementation that creates an ApplicationInstance
    # In a real implementation, this would also create the tenant/schema
    ApplicationInstance.create!(
      application: app,
      lti_key: "test-lti-key-#{site_url}"
    )
  end

  # Implement find_application_instance to work with the dummy app structure
  # In real apps, this would query by tenant field/relationship
  def find_application_instance(current_application, site_url, issuer, platform_guid)
    ApplicationInstance.find_by(
      application: current_application,
      lti_key: "test-lti-key-#{site_url}"
    )
  end
end

RSpec.describe AtomicTenant::DeploymentManager::AbstractAutoCreatePlatformGuidStrategy do
  let(:strategy) { TestAutoCreateStrategy.new }
  let!(:application) { create(:application, key: "lti-example") }
  let(:base_decoded_token) do
    {
      "iss" => "https://canvas.instructure.com",
      "https://purl.imsglobal.org/spec/lti/claim/tool_platform" => {
        "guid" => "test-platform-guid",
        "product_family_code" => "canvas"
      },
      "https://purl.imsglobal.org/spec/lti/claim/target_link_uri" => "https://lti-example.example.com/lti_launches",
      "https://purl.imsglobal.org/spec/lti/claim/custom" => {
        "canvas_api_domain" => "atomicjolt.instructure.com"
      }
    }
  end

  describe "#name" do
    it "raises NotImplementedError for abstract class" do
      abstract_strategy = AtomicTenant::DeploymentManager::AbstractAutoCreatePlatformGuidStrategy.new
      expect { abstract_strategy.name }.to raise_error(NotImplementedError, "Subclasses must implement #name")
    end

    it "returns the strategy name for concrete implementation" do
      expect(strategy.name).to eq("TestAutoCreateStrategy")
    end
  end

  describe "#call" do
    context "with missing platform_guid" do
      let(:decoded_token) { base_decoded_token.tap { |t| t["https://purl.imsglobal.org/spec/lti/claim/tool_platform"].delete("guid") } }

      it "returns empty result" do
        result = strategy.call(decoded_id_token: decoded_token)
        expect(result).to be_a(AtomicTenant::DeploymentManager::DeploymentStrategyResult)
        expect(result.application_instance_id).to be_nil
      end
    end

    context "with missing target_link_uri" do
      let(:decoded_token) { base_decoded_token.tap { |t| t.delete("https://purl.imsglobal.org/spec/lti/claim/target_link_uri") } }

      it "returns empty result" do
        result = strategy.call(decoded_id_token: decoded_token)
        expect(result).to be_a(AtomicTenant::DeploymentManager::DeploymentStrategyResult)
        expect(result.application_instance_id).to be_nil
      end
    end

    context "with missing application_key from target_link_uri" do
      let(:decoded_token) { base_decoded_token.tap { |t| t["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"] = "https://" } }

      it "returns empty result" do
        result = strategy.call(decoded_id_token: decoded_token)
        expect(result).to be_a(AtomicTenant::DeploymentManager::DeploymentStrategyResult)
        expect(result.application_instance_id).to be_nil
      end
    end

    context "with invalid application_key from target_link_uri" do
      let(:decoded_token) { base_decoded_token.tap { |t| t["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"] = "https://invalid-application.example.com" } }

      it "returns empty result" do
        result = strategy.call(decoded_id_token: decoded_token)
        expect(result).to be_a(AtomicTenant::DeploymentManager::DeploymentStrategyResult)
        expect(result.application_instance_id).to be_nil
      end
    end

    context "with trusted issuer creating new instance" do
      let(:decoded_token) { base_decoded_token }

      it "creates application instance with pinned platform guid" do
        result = strategy.call(decoded_id_token: decoded_token)
        expect(result).to be_a(AtomicTenant::DeploymentManager::DeploymentStrategyResult)
        expect(result.application_instance_id).to be_present

        # Verify the application instance was created
        app_instance = ApplicationInstance.find(result.application_instance_id)
        expect(app_instance.application).to eq(application)

        # Verify pinned platform guid was created
        pinned_guid = AtomicTenant::PinnedPlatformGuid.find_by(
          iss: "https://canvas.instructure.com",
          platform_guid: "test-platform-guid",
          application_id: application.id,
          application_instance_id: result.application_instance_id
        )
        expect(pinned_guid).to be_present
      end

      it "allows creating unlimited instances for trusted issuers" do
        # Set a low limit for testing
        AtomicTenant.untrusted_iss_tenant_limit = 1

        # Create an existing instance from the same trusted issuer
        existing = create(:application_instance, application: application)
        AtomicTenant::LtiDeployment.create!(
          iss: "https://canvas.instructure.com",
          application_instance: existing,
          deployment_id: "existing-deployment"
        )

        # Should still allow creating a new instance because issuer is trusted
        expect do
          result = strategy.call(decoded_id_token: decoded_token)
          expect(result.application_instance_id).not_to eq(existing.id)
          expect(result.application_instance_id).to be_present
        end.not_to raise_error
      end
    end

    context "with existing application instance" do
      let(:decoded_token) { base_decoded_token }
      let!(:existing_app_instance) do
        create(:application_instance,
          application: application,
          lti_key: "test-lti-key-https://atomicjolt.instructure.com"
        )
      end

      it "finds existing application instance" do
        result = strategy.call(decoded_id_token: decoded_token)
        expect(result.application_instance_id).to eq(existing_app_instance.id)
      end
    end

    context "with untrusted issuer" do
      let(:decoded_token) { base_decoded_token.tap { |t| t["iss"] = "https://untrusted.example.com" } }

      before do
        AtomicTenant.untrusted_iss_tenant_limit = 5
      end

      context "when under tenant limit" do
        before do
          # Create fewer than the limit
          3.times do |i|
            app_inst = create(:application_instance, application: application)
            AtomicTenant::LtiDeployment.create!(
              iss: "https://untrusted.example.com",
              application_instance: app_inst,
              deployment_id: "deployment-#{i}"
            )
          end
        end

        it "allows creation of new instance" do
          expect { strategy.call(decoded_id_token: decoded_token) }.not_to raise_error
        end
      end

      context "when at tenant limit" do
        before do
          # Create exactly the limit
          5.times do |i|
            app_inst = create(:application_instance, application: application)
            AtomicTenant::LtiDeployment.create!(
              iss: "https://untrusted.example.com",
              application_instance: app_inst,
              deployment_id: "deployment-#{i}"
            )
          end
        end

        it "raises OnboardingException" do
          expect {
            strategy.call(decoded_id_token: decoded_token)
          }.to raise_error(AtomicTenant::Exceptions::OnboardingException, /has reached the limit/)
        end
      end
    end
  end

  describe "platform-specific tenant creation" do
    context "with Canvas platform" do
      let(:decoded_token) do
        base_decoded_token.merge(
          "iss" => "https://canvas.instructure.com",
          "https://purl.imsglobal.org/spec/lti/claim/tool_platform" => {
            "guid" => "canvas-guid-123",
            "product_family_code" => "canvas"
          },
          "https://purl.imsglobal.org/spec/lti/claim/custom" => {
            "canvas_api_domain" => "custom.canvas.com"
          }
        )
      end

      it "calls create_application_instance with correct site_url from canvas_api_domain" do
        mock_app_instance = create(:application_instance, application: application)

        expect(strategy).to receive(:find_application_instance)
          .with(application, "https://custom.canvas.com", "https://canvas.instructure.com", "canvas-guid-123")
          .and_return(nil)

        expect(strategy).to receive(:create_application_instance)
          .with(application, "https://custom.canvas.com", "https://canvas.instructure.com", "canvas-guid-123")
          .and_return(mock_app_instance)

        result = strategy.call(decoded_id_token: decoded_token)
        expect(result.application_instance_id).to eq(mock_app_instance.id)
      end

      it "calls find_application_instance with correct site_url from canvas_api_domain" do
        mock_app_instance = create(:application_instance, application: application)

        expect(strategy).to receive(:find_application_instance)
          .with(application, "https://custom.canvas.com", "https://canvas.instructure.com", "canvas-guid-123")
          .and_return(mock_app_instance)

        result = strategy.call(decoded_id_token: decoded_token)
        expect(result.application_instance_id).to eq(mock_app_instance.id)
      end

      it "raises OnboardingException when canvas_api_domain is missing" do
        invalid_token = decoded_token.tap { |t| t["https://purl.imsglobal.org/spec/lti/claim/custom"] = {} }

        expect {
          strategy.call(decoded_id_token: invalid_token)
        }.to raise_error(AtomicTenant::Exceptions::OnboardingException, /Missing canvas_api_domain/)
      end
    end

    context "with Blackboard platform" do
      let(:decoded_token) do
        base_decoded_token.merge(
          "iss" => "https://blackboard.com",
          "https://purl.imsglobal.org/spec/lti/claim/tool_platform" => {
            "guid" => "bb-guid-456",
            "product_family_code" => "BlackboardLearn",
            "url" => "blackboard.example.com"
          }
        )
      end

      it "calls create_application_instance with correct site_url from platform url" do
        mock_app_instance = create(:application_instance, application: application)

        expect(strategy).to receive(:find_application_instance)
          .with(application, "https://blackboard.example.com", "https://blackboard.com", "bb-guid-456")
          .and_return(nil)

        expect(strategy).to receive(:create_application_instance)
          .with(application, "https://blackboard.example.com", "https://blackboard.com", "bb-guid-456")
          .and_return(mock_app_instance)

        result = strategy.call(decoded_id_token: decoded_token)
        expect(result.application_instance_id).to eq(mock_app_instance.id)
      end

      it "calls find_application_instance with correct site_url from platform url" do
        mock_app_instance = create(:application_instance, application: application)

        expect(strategy).to receive(:find_application_instance)
          .with(application, "https://blackboard.example.com", "https://blackboard.com", "bb-guid-456")
          .and_return(mock_app_instance)

        result = strategy.call(decoded_id_token: decoded_token)
        expect(result.application_instance_id).to eq(mock_app_instance.id)
      end

      it "raises OnboardingException when platform url is missing" do
        invalid_token = decoded_token.tap do |t|
          t["https://purl.imsglobal.org/spec/lti/claim/tool_platform"].delete("url")
        end

        expect {
          strategy.call(decoded_id_token: invalid_token)
        }.to raise_error(AtomicTenant::Exceptions::OnboardingException, /Missing url in platform claim/)
      end
    end

    context "with D2L platform" do
      let(:decoded_token) do
        base_decoded_token.merge(
          "iss" => "https://atomicjolt.brightspace.com",
          "https://purl.imsglobal.org/spec/lti/claim/tool_platform" => {
            "guid" => "d2l-guid-789",
            "product_family_code" => "desire2learn"
          }
        )
      end

      it "calls create_application_instance with correct site_url from issuer" do
        mock_app_instance = create(:application_instance, application: application)

        expect(strategy).to receive(:find_application_instance)
          .with(application, "https://atomicjolt.brightspace.com", "https://atomicjolt.brightspace.com", "d2l-guid-789")
          .and_return(nil)

        expect(strategy).to receive(:create_application_instance)
          .with(application, "https://atomicjolt.brightspace.com", "https://atomicjolt.brightspace.com", "d2l-guid-789")
          .and_return(mock_app_instance)

        result = strategy.call(decoded_id_token: decoded_token)
        expect(result.application_instance_id).to eq(mock_app_instance.id)
      end

      it "calls find_application_instance with correct site_url from issuer" do
        mock_app_instance = create(:application_instance, application: application)

        expect(strategy).to receive(:find_application_instance)
          .with(application, "https://atomicjolt.brightspace.com", "https://atomicjolt.brightspace.com", "d2l-guid-789")
          .and_return(mock_app_instance)

        result = strategy.call(decoded_id_token: decoded_token)
        expect(result.application_instance_id).to eq(mock_app_instance.id)
      end
    end
  end

  describe "concurrent platform guid creation" do
    let(:decoded_token) do
      base_decoded_token.merge(
        "iss" => "https://existing.platform.com",
        "https://purl.imsglobal.org/spec/lti/claim/tool_platform" => {
          "guid" => "existing-platform-guid",
          "product_family_code" => "moodle"
        }
      )
    end
    let(:existing_app_instance) do
      create(:application_instance,
        application: application,
        lti_key: "test-lti-key-https://existing.platform.com"
      )
    end
    let!(:existing_pinned_guid) do
      AtomicTenant::PinnedPlatformGuid.create!(
        iss: "https://existing.platform.com",
        platform_guid: "existing-platform-guid",
        application_id: application.id,
        application_instance_id: existing_app_instance.id
      )
    end

    it "returns existing application instance when found" do
      result = strategy.call(decoded_id_token: decoded_token)

      expect(result.application_instance_id).to eq(existing_app_instance.id)

      pinned_guids = AtomicTenant::PinnedPlatformGuid.where(
        iss: "https://existing.platform.com",
        platform_guid: "existing-platform-guid",
        application_id: application.id
      )

      expect(pinned_guids.count).to eq(1)
      expect(pinned_guids.first).to eq(existing_pinned_guid)
    end
  end

  describe "concurrent instance creation handling" do
    let(:decoded_token) { base_decoded_token }

    context "when RecordNotUnique is raised during creation" do
      it "calls find_application_instance twice when creation fails" do
        mock_app_instance = create(:application_instance, application: application)

        # Simulate concurrent creation by making create_application_instance raise RecordNotUnique
        allow_any_instance_of(TestAutoCreateStrategy).to receive(:create_application_instance).and_raise(ActiveRecord::RecordNotUnique)

        # Expect find_application_instance to be called twice - first returns nil, second returns the instance
        expect_any_instance_of(TestAutoCreateStrategy).to receive(:find_application_instance)
          .and_return(nil, mock_app_instance)

        strategy.call(decoded_id_token: decoded_token)
      end
    end
  end
end
