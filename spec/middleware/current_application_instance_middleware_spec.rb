require 'rails_helper'

RSpec.describe AtomicTenant::CurrentApplicationInstanceMiddleware do
  let(:app) { ->(env) { [200, env, 'app'] } }
  let(:middleware) { described_class.new(app) }
  let(:env) { Rack::MockRequest.env_for }

  describe '#call' do
    context 'when oauth_consumer_key is present' do
      let(:application_instance) { create(:application_instance) }

      before do
        env['atomic.validated.oauth_consumer_key'] = application_instance.lti_key
      end

      it 'sets the application_instance_id in the env' do
        middleware.call(env)
        expect(env['atomic.validated.application_instance_id']).to eq(application_instance.id)
      end
    end

    context 'when id_token is present' do
      let(:decoded_id_token) do
        {
          'iss' => 'issuer',
          'aud' => 'client_id',
          AtomicLti::Definitions::DEPLOYMENT_ID => 'deployment_id',
          AtomicLti::Definitions::TOOL_PLATFORM_CLAIM => { 'guid' => 'platform_guid' },
          AtomicLti::Definitions::TARGET_LINK_URI_CLAIM => "https://#{application_instance.application.key}.example.com"
        }
      end
      let(:application_instance) { create(:application_instance) }

      describe 'finding app instance by deployment' do
        before do
          create(
            :atomic_tenant_lti_deployment, iss: 'issuer', deployment_id: 'deployment_id',
                                           application_instance: application_instance
          )
          env['atomic.validated.id_token'] = 'id_token'
          env['atomic.validated.decoded_id_token'] = decoded_id_token
        end

        it 'sets the application_instance_id in the env' do
          middleware.call(env)
          expect(env['atomic.validated.application_instance_id']).to eq(application_instance.id)
        end
      end

      describe 'finding app instance by pinned platform guid' do
        before do
          create(
            :atomic_tenant_pinned_platform_guid,
            iss: 'issuer', platform_guid: 'platform_guid',
            application: application_instance.application,
            application_instance: application_instance
          )
          env['atomic.validated.id_token'] = 'id_token'
          env['atomic.validated.decoded_id_token'] = decoded_id_token
        end

        it 'sets application_instance_id in the env' do
          middleware.call(env)
          expect(env['atomic.validated.application_instance_id']).to eq(application_instance.id)
        end
      end

      describe 'finding app instance by pinned client id' do
        before do
          create(
            :atomic_tenant_pinned_client_id,
            iss: 'issuer', client_id: 'client_id',
            application_instance: application_instance
          )
          env['atomic.validated.id_token'] = 'id_token'
          env['atomic.validated.decoded_id_token'] = decoded_id_token
        end

        it 'sets application_instance_id in the env' do
          middleware.call(env)
          expect(env['atomic.validated.application_instance_id']).to eq(application_instance.id)
        end
      end
    end

    context 'when oauth_state application_instance_id is present' do
      before do
        env['oauth_state'] = { 'application_instance_id' => 1 }
      end

      it 'sets the application_instance_id in the env' do
        middleware.call(env)
        expect(env['atomic.validated.application_instance_id']).to eq(1)
      end
    end

    context 'when request is at /readiness' do
      let(:env) { Rack::MockRequest.env_for('/readiness', 'HTTP_HOST' => 'admin.example.com') }
      let(:admin_app) { create(:application, key: 'admin') }

      it 'sets the admin app application_instance_id in the env' do
        application_instance = create(:application_instance, application: admin_app)
        middleware.call(env)
        expect(env['atomic.validated.application_instance_id']).to eq(application_instance.id)
      end
    end

    context 'when request is admin and not at /readiness' do
      let(:env) { Rack::MockRequest.env_for('/', 'HTTP_HOST' => 'admin.example.com') }
      let(:admin_app) { create(:application, key: 'admin') }

      it 'sets the admin app application_instance_id in the env' do
        application_instance = create(:application_instance, application: admin_app)
        middleware.call(env)
        expect(env['atomic.validated.application_instance_id']).to eq(application_instance.id)
      end
    end

    context 'when request is a canvas migration hook' do
      let(:env) { Rack::MockRequest.env_for("/api/ims_import?jwt=#{token}") }
      let(:app_instance) { create(:application_instance) }
      let(:token) { JWT.encode({}, nil, 'none', { 'kid' => app_instance.lti_key }) }

      it 'sets the application_instance_id in the env' do
        middleware.call(env)
        expect(env['atomic.validated.application_instance_id']).to eq(app_instance.id)
      end
    end

    context 'when encoded token is present' do
      let(:env) { Rack::MockRequest.env_for('/?jwt=token') }
      let(:decoded_token) { [{ 'application_instance_id' => 1 }] }

      before do
        allow(AtomicTenant::JwtToken).to receive(:decode).and_return(decoded_token)
      end

      it 'sets the application_instance_id in the env' do
        middleware.call(env)
        expect(env['atomic.validated.application_instance_id']).to eq(1)
      end
    end
  end
end
