module AtomicTenant
  module CanvasContentMigration
    class InvalidTokenError < StandardError; end

    ALGORITHM = "HS256".freeze
    HEADER = 1

    # Decode Canvas content migration JWT
    # https://canvas.instructure.com/doc/api/file.tools_xml.html#content-migrations-support

    def self.decode(token,  algorithm = ALGORITHM)
      unverified = JWT.decode(token, nil, false)
      kid = unverified[HEADER]["kid"]
      app_instance = ApplicationInstance.find_by!(lti_key: kid)
      decoded_token = JWT.decode(
        token,
        app_instance.lti_secret,
        true,
        { algorithm: algorithm },
      )
      [decoded_token, app_instance]
    end
  end
end
