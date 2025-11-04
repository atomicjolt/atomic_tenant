require "rails_helper"

RSpec.describe AtomicTenant::DeploymentManager::DeploymentManager do
  let(:iss) { "https://example.com" }
  let(:deployment_id) { "deployment_123" }
  let(:decoded_id_token) do
    {
      "iss" => iss,
      AtomicLti::Definitions::DEPLOYMENT_ID => deployment_id
    }
  end
  let!(:application_instance) { create(:application_instance) }

  describe "#link_deployment_id" do
    context "with single matching strategy" do
      let(:strategy) do
        MockStrategy.new(
          name: "test_strategy",
          application_instance_id: application_instance.id
        )
      end
      let(:manager) { described_class.new([strategy]) }

      it "successfully links deployment" do
        deployment = manager.link_deployment_id(decoded_id_token: decoded_id_token)

        expect(deployment).to be_present
        expect(deployment.iss).to eq(iss)
        expect(deployment.deployment_id).to eq(deployment_id)
        expect(deployment.application_instance_id).to eq(application_instance.id)
      end

      it "logs standard linking message" do
        expect(Rails.logger).to receive(:info).with(
          "Linking iss / deployment id: #{iss} / #{deployment_id} to application instance: #{application_instance.id}"
        )

        manager.link_deployment_id(decoded_id_token: decoded_id_token)
      end
    end

    context "with colliding strategies" do
      let(:application_instance2) { create(:application_instance) }
      let(:strategy1) do
        MockStrategy.new(
          name: "strategy_1",
          application_instance_id: application_instance.id
        )
      end
      let(:strategy2) do
        MockStrategy.new(
          name: "strategy_2",
          application_instance_id: application_instance2.id
        )
      end
      let(:manager) { described_class.new([strategy1, strategy2]) }

      it "uses the first matching strategy" do
        deployment = manager.link_deployment_id(decoded_id_token: decoded_id_token)

        expect(deployment).to be_present
        expect(deployment.iss).to eq(iss)
        expect(deployment.deployment_id).to eq(deployment_id)
        expect(deployment.application_instance_id).to eq(application_instance.id)
      end

      it "logs colliding strategies message with to_link defined" do
        allow(Rails.logger).to receive(:debug).and_call_original
        allow(Rails.logger).to receive(:info).and_call_original

        expect(Rails.logger).to receive(:info).with(
          a_string_including(
            "Colliding strategies",
            iss,
            deployment_id,
            "application instance: #{application_instance.id}",
            "all results:"
          )
        ).and_call_original

        manager.link_deployment_id(decoded_id_token: decoded_id_token)
      end
    end

    context "when no strategies match" do
      let(:strategy) do
        MockStrategy.new(
          name: "test_strategy",
          application_instance_id: nil
        )
      end
      let(:manager) { described_class.new([strategy]) }

      it "raises UnableToLinkDeploymentError" do
        expect {
          manager.link_deployment_id(decoded_id_token: decoded_id_token)
        }.to raise_error(AtomicTenant::Exceptions::UnableToLinkDeploymentError)
      end
    end

    context "with strategy errors" do
      let(:failing_strategy) { FailingStrategy.new(name: "failing_strategy") }
      let(:working_strategy) do
        MockStrategy.new(
          name: "working_strategy",
          application_instance_id: application_instance.id
        )
      end
      let(:manager) { described_class.new([failing_strategy, working_strategy]) }

      it "handles errors gracefully and continues with other strategies" do
        expect(Rails.logger).to receive(:error) do |message|
          expect(message).to include("Error in lti deployment linking strategy")
          expect(message).to include("failing_strategy")
        end

        deployment = manager.link_deployment_id(decoded_id_token: decoded_id_token)

        expect(deployment).to be_present
        expect(deployment.application_instance_id).to eq(application_instance.id)
      end
    end

    context "when all strategies fail" do
      let(:failing_strategy1) { FailingStrategy.new(name: "failing_1") }
      let(:failing_strategy2) { FailingStrategy.new(name: "failing_2") }
      let(:manager) { described_class.new([failing_strategy1, failing_strategy2]) }

      it "raises UnableToLinkDeploymentError" do
        expect(Rails.logger).to receive(:error).twice

        expect {
          manager.link_deployment_id(decoded_id_token: decoded_id_token)
        }.to raise_error(AtomicTenant::Exceptions::UnableToLinkDeploymentError)
      end
    end

    context "with empty strategies array" do
      let(:manager) { described_class.new([]) }

      it "raises UnableToLinkDeploymentError" do
        expect {
          manager.link_deployment_id(decoded_id_token: decoded_id_token)
        }.to raise_error(AtomicTenant::Exceptions::UnableToLinkDeploymentError)
      end
    end

    context "debug logging" do
      let(:strategy1) do
        MockStrategy.new(
          name: "strategy_1",
          application_instance_id: application_instance.id,
          details: "first match"
        )
      end
      let(:strategy2) do
        MockStrategy.new(
          name: "strategy_2",
          application_instance_id: nil
        )
      end
      let(:manager) { described_class.new([strategy1, strategy2]) }

      it "logs debug information about all results" do
        allow(Rails.logger).to receive(:debug).and_call_original
        allow(Rails.logger).to receive(:info).and_call_original

        expect(Rails.logger).to receive(:debug).with(
          a_string_including("Linking Results:")
        ).and_call_original

        manager.link_deployment_id(decoded_id_token: decoded_id_token)
      end
    end
  end

  # Mock Strategy class for testing
  class MockStrategy < AtomicTenant::DeploymentManager::DeploymentManagerStrategy
    attr_reader :strategy_name

    def initialize(name:, application_instance_id:, details: nil)
      @strategy_name = name
      @application_instance_id = application_instance_id
      @details = details
    end

    def name
      @strategy_name
    end

    def call(decoded_id_token:)
      AtomicTenant::DeploymentManager::DeploymentStrategyResult.new(
        application_instance_id: @application_instance_id,
        details: @details
      )
    end
  end

  # Failing Strategy class for testing error handling
  class FailingStrategy < AtomicTenant::DeploymentManager::DeploymentManagerStrategy
    attr_reader :strategy_name

    def initialize(name:)
      @strategy_name = name
    end

    def name
      @strategy_name
    end

    def call(decoded_id_token:)
      raise StandardError, "Strategy failed"
    end
  end
end
