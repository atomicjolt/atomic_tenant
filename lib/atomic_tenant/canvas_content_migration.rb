module AtomicTenant
  module CanvasContentMigration
    class InvalidTokenError < StandardError; end

    ALGORITHM = 'HS256'.freeze
    HEADER = 1

    # Decode Canvas content migration JWT
    # https://canvas.instructure.com/doc/api/file.tools_xml.html#content-migrations-support

    def self.decode(token, algorithm = ALGORITHM)
      unverified = JWT.decode(token, nil, false)
      kid = unverified[HEADER]['kid']
      ApplicationInstance.find_by!(lti_key: kid)
      # We don't validate because we're only setting the tenant for the request. The app
      # must validate the JWT.
    end
  end
end
