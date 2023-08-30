module AtomicTenant
  module JwtToken
    class InvalidTokenError < StandardError; end

    ALGORITHM = "HS512".freeze

    def self.decode(token,  algorithm: ALGORITHM, validate: true)
      decoded_token = JWT.decode(
        token,
        AtomicTenant.jwt_secret,
        validate,
        { algorithm: algorithm },
      )
      if AtomicTenant.jwt_aud != decoded_token[0]["aud"]
        return nil
      end

      decoded_token
    end

    def self.valid?(token, algorithm = ALGORITHM)
      decode(token, algorithm)
    end

    def decoded_jwt_token(req)
      token = valid?(encoded_token(req))
      raise InvalidTokenError, 'Unable to decode jwt token' if token.blank?
      raise InvalidTokenError, 'Invalid token payload' if token.empty?

      token[0]
    end

    def validate_token_with_secret(aud, secret, req = request)
      token = decoded_jwt_token(req, secret)
      raise InvalidTokenError if aud != token['aud']
    rescue JWT::DecodeError, InvalidTokenError => e
      Rails.logger.error "JWT Error occured: #{e.inspect}"
      render json: { error: 'Unauthorized: Invalid token.' }, status: :unauthorized
    end

    def encoded_token!(req)
      return req.params[:jwt] if req.params[:jwt]

      header = req.headers['Authorization'] || req.headers[:authorization]
      raise InvalidTokenError, 'No authorization header found' if header.nil?

      token = header.split(' ').last
      raise InvalidTokenError, 'Invalid authorization header string' if token.nil?

      token
    end

    def encoded_token(req)
      return req.params[:jwt] if req.params[:jwt]

      if header = req.headers['Authorization'] || req.headers[:authorization]
        header.split(' ').last
      end
    end
  end
end
