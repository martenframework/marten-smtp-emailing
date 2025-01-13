module MartenSMTPEmailing
  # An SMTP emailing backend.
  class Backend < Marten::Emailing::Backend::Base
    @smtp_config : EMail::Client::Config?

    getter host
    getter port
    getter helo_domain
    getter username
    getter password
    getter? use_tls

    def initialize(
      @host : String = "localhost",
      @port : Int32 = 25,
      @helo_domain : String = "localhost",
      @use_tls : Bool = true,
      @username : String? = nil,
      @password : String? = nil,
    )
    end

    def deliver(email : Marten::Emailing::Email) : Nil
      ::EMail.send(smtp_config) do
        unless (email_subject = email.subject).nil?
          subject(email_subject)
        end

        from(email.from.address, email.from.name)
        email.to.each { |to_address| to(to_address.address, to_address.name) }

        unless (email_cc = email.cc).nil?
          email_cc.each { |cc_address| cc(cc_address.address, cc_address.name) }
        end

        unless (email_bcc = email.bcc).nil?
          email_bcc.each { |bcc_address| bcc(bcc_address.address, bcc_address.name) }
        end

        unless (reply_to = email.reply_to).nil?
          reply_to(reply_to.address, reply_to.name)
        end

        email.headers.each do |key, value|
          case key.downcase
          when "message-id"
            message_id(value)
          when "return-path"
            return_path(value)
          when "sender"
            sender(value)
          else
            custom_header(key, value)
          end
        end

        unless (text_body = email.text_body).nil?
          message(text_body)
        end

        unless (html_body = email.html_body).nil?
          message_html(html_body)
        end
      end
    end

    private def auth
      return if username.nil? && password.nil?

      {username.to_s, password.to_s}
    end

    private def smtp_config
      @smtp_config ||= EMail::Client::Config.create(
        host,
        port,
        auth: auth,
        use_tls: use_tls? ? ::EMail::Client::TLSMode::STARTTLS : ::EMail::Client::TLSMode::NONE,
        helo_domain: helo_domain
      )
    end
  end
end
