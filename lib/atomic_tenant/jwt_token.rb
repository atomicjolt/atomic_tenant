module AtomicTenant
  module JwtToken
    class InvalidTokenError < StandardError; end

    ALGORITHM = 'HS512'.freeze

    def self.decode(token, algorithm = ALGORITHM, validate: true)
      decoded_token = JWT.decode(
        token,
        AtomicTenant.jwt_secret,
        validate,
        { algorithm: algorithm }
      )
      return nil if AtomicTenant.jwt_aud != decoded_token[0]['aud']

      decoded_token
    end
  end
end
