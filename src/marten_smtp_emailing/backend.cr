module MartenSMTPEmailing
  # Raised when SMTP delivery fails: a failed connection or handshake, or a
  # message the server rejects.
  class DeliveryError < Exception; end

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
      message = build_message(email)

      # `EMail::Client#start` swallows connection/handshake errors (the block
      # never runs) and `#send` returns false on rejection — neither raises.
      sent = false
      ::EMail::Client.new(smtp_config).start do
        sent = send(message)
      end

      unless sent
        raise DeliveryError.new("SMTP delivery failed to #{email.to.map(&.address).join(", ")}")
      end
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
