require 'rails_helper'
require 'jwt'

RSpec.describe AtomicTenant::JwtToken do
  let(:secret) { 'test_secret' }
  let(:aud) { 'test_aud' }
  let(:token) { JWT.encode({ aud: aud }, secret, 'HS512') }
  let(:invalid_token) { 'invalid.token.string' }
  let(:req) { double('request', params: {}, headers: {}) }

  before do
    allow(AtomicTenant).to receive(:jwt_secret).and_return(secret)
    allow(AtomicTenant).to receive(:jwt_aud).and_return(aud)
  end

  describe '.decode' do
    it 'decodes a valid token' do
      decoded_token = described_class.decode(token)
      expect(decoded_token[0]['aud']).to eq(aud)
    end

    it 'returns nil for an invalid audience' do
      allow(AtomicTenant).to receive(:jwt_aud).and_return('invalid_aud')
      expect(described_class.decode(token)).to be_nil
    end
  end
end
