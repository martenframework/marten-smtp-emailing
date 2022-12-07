require "./spec_helper"

describe MartenSMTPEmailing::Backend do
  describe "#deliver" do
    it "sends a simple email as expected" do
      backend = MartenSMTPEmailing::Backend.new(use_tls: false, port: SMTP_PORT)
      backend.deliver(MartenSMTPEmailing::BackendSpec::TestEmail.new)

      EMAIL_STORE.count.should eq 1
      email = EMAIL_STORE.messages.last
      email.should match(/From: John Doe <from@example\.com>/)
      email.should match(/To: to@example\.com/)
      email.should match(/Subject: Hello World!/)
      email.should match(/Content-Type: text\/plain/)
      email.should match(/HTML body/)
      email.should match(/Text body/)
    end

    it "sends an email with CC addresses as expected" do
      backend = MartenSMTPEmailing::Backend.new(use_tls: false, port: SMTP_PORT)
      backend.deliver(MartenSMTPEmailing::BackendSpec::TestEmailWithCc.new)

      EMAIL_STORE.count.should eq 1
      email = EMAIL_STORE.messages.last
      email.should match(/Cc: cc1@example\.com, cc2@example\.com/)
    end

    it "sends an email with a reply-to address as expected" do
      backend = MartenSMTPEmailing::Backend.new(use_tls: false, port: SMTP_PORT)
      backend.deliver(MartenSMTPEmailing::BackendSpec::TestEmailWithReplyTo.new)

      EMAIL_STORE.count.should eq 1
      email = EMAIL_STORE.messages.last
      email.should match(/Reply-To: replyto@example\.com/)
    end

    it "sends an email with a return-path header" do
      backend = MartenSMTPEmailing::Backend.new(use_tls: false, port: SMTP_PORT)
      backend.deliver(
        MartenSMTPEmailing::BackendSpec::TestEmailWithHeaders.new(
          {"Return-Path" => "test@example.com"}
        )
      )

      EMAIL_STORE.count.should eq 1
      email = EMAIL_STORE.messages.last
      email.should match(/Return-Path: test@example.com/)
    end

    it "sends an email with a sender header" do
      backend = MartenSMTPEmailing::Backend.new(use_tls: false, port: SMTP_PORT)
      backend.deliver(
        MartenSMTPEmailing::BackendSpec::TestEmailWithHeaders.new(
          {"Sender" => "test@example.com"}
        )
      )

      EMAIL_STORE.count.should eq 1
      email = EMAIL_STORE.messages.last
      email.should match(/Sender: test@example.com/)
    end

    it "sends an email with custom header values" do
      backend = MartenSMTPEmailing::Backend.new(use_tls: false, port: SMTP_PORT)
      backend.deliver(MartenSMTPEmailing::BackendSpec::TestEmailWithHeaders.new({"Foo" => "bar"}))

      EMAIL_STORE.count.should eq 1
      email = EMAIL_STORE.messages.last
      email.should match(/Foo: bar/)
    end
  end

  describe "#helo_domain" do
    it "returns localhost by default" do
      backend = MartenSMTPEmailing::Backend.new
      backend.helo_domain.should eq "localhost"
    end

    it "returns the configured helo domain" do
      backend = MartenSMTPEmailing::Backend.new(helo_domain: "test.example.com")
      backend.helo_domain.should eq "test.example.com"
    end
  end

  describe "#host" do
    it "returns localhost by default" do
      backend = MartenSMTPEmailing::Backend.new
      backend.host.should eq "localhost"
    end

    it "returns the configured host" do
      backend = MartenSMTPEmailing::Backend.new(host: "test.example.com")
      backend.host.should eq "test.example.com"
    end
  end

  describe "#password" do
    it "returns nil by default" do
      backend = MartenSMTPEmailing::Backend.new
      backend.password.should be_nil
    end

    it "returns the configured username" do
      backend = MartenSMTPEmailing::Backend.new(password: "testpassword")
      backend.password.should eq "testpassword"
    end
  end

  describe "#port" do
    it "returns 25 by default" do
      backend = MartenSMTPEmailing::Backend.new
      backend.port.should eq 25
    end

    it "returns the configured port" do
      backend = MartenSMTPEmailing::Backend.new(port: 30025)
      backend.port.should eq 30025
    end
  end

  describe "#username" do
    it "returns nil by default" do
      backend = MartenSMTPEmailing::Backend.new
      backend.username.should be_nil
    end

    it "returns the configured username" do
      backend = MartenSMTPEmailing::Backend.new(username: "testuser")
      backend.username.should eq "testuser"
    end
  end

  describe "#use_tls?" do
    it "returns true by default" do
      backend = MartenSMTPEmailing::Backend.new
      backend.use_tls?.should be_true
    end

    it "returns false if configured as such" do
      backend = MartenSMTPEmailing::Backend.new(use_tls: false)
      backend.use_tls?.should be_false
    end
  end
end

module MartenSMTPEmailing::BackendSpec
  class TestEmail < Marten::Email
    subject "Hello World!"
    to "to@example.com"

    def from
      Marten::Emailing::Address.new(address: "from@example.com", name: "John Doe")
    end

    def html_body
      "HTML body"
    end

    def text_body
      "Text body"
    end
  end

  class TestEmailWithCc < TestEmail
    cc ["cc1@example.com", "cc2@example.com"]
  end

  class TestEmailWithReplyTo < TestEmail
    reply_to "replyto@example.com"
  end

  class TestEmailWithHeaders < TestEmail
    def initialize(@headers)
    end

    def headers
      @headers
    end
  end
end
