ENV["MARTEN_ENV"] = "test"

require "spec"

require "devmail/store"
require "devmail/smtp_server"
require "marten"
require "marten/spec"

require "../src/marten_smtp_emailing"

require "./test_project"

EMail::Client.log_level = ::Log::Severity::None

EMAIL_STORE = Store.new
SMTP_PORT   = 30025
SMTP_SERVER = SMTPServer.new(EMAIL_STORE, SMTP_PORT)
SMTP_SERVER.run

Spec.before_each { EMAIL_STORE.messages.clear }
