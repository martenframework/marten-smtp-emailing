module MartenSMTPEmailing
  # An SMTP emailing backend.
  class Backend < Marten::Emailing::Backend::Base
    # Raised when SMTP delivery fails: a failed connection or handshake, or a
    # message the server rejects.
    class DeliveryError < Exception; end

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
      message = build_message(email)
      error_message = "SMTP delivery failed to #{email.to.map(&.address).join(", ")}"

      # `EMail::Client#start` does not yield on a failed handshake, and `#send`
      # returns false on rejection. Connection errors are re-raised via the
      # default `on_fatal_error` handler; wrap them so callers only rescue
      # `DeliveryError`.
      sent = false
      begin
        ::EMail::Client.new(smtp_config).start do
          sent = send(message)
        end
      rescue ex
        raise DeliveryError.new(error_message, cause: ex)
      end

      raise DeliveryError.new(error_message) unless sent
    end

    private def build_message(email : Marten::Emailing::Email) : ::EMail::Message
      message = ::EMail::Message.new

      unless (email_subject = email.subject).nil?
        message.subject(email_subject)
      end

      message.from(email.from.address, email.from.name)
      email.to.each { |to_address| message.to(to_address.address, to_address.name) }

      unless (email_cc = email.cc).nil?
        email_cc.each { |cc_address| message.cc(cc_address.address, cc_address.name) }
      end

      unless (email_bcc = email.bcc).nil?
        email_bcc.each { |bcc_address| message.bcc(bcc_address.address, bcc_address.name) }
      end

      unless (reply_to = email.reply_to).nil?
        message.reply_to(reply_to.address, reply_to.name)
      end

      email.headers.each do |key, value|
        case key.downcase
        when "message-id"
          message.message_id(value)
        when "return-path"
          message.return_path(value)
        when "sender"
          message.sender(value)
        else
          message.custom_header(key, value)
        end
      end

      unless (text_body = email.text_body).nil?
        message.message(text_body)
      end

      unless (html_body = email.html_body).nil?
        message.message_html(html_body)
      end

      email.attachments.each do |attachment|
        message.attach(
          IO::Memory.new(attachment.content),
          file_name: attachment.filename,
          mime_type: attachment.mime_type,
        )
      end

      message
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
