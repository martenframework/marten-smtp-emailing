# Marten SMTP Emailing

[![CI](https://github.com/martenframework/marten-smtp-emailing/workflows/Specs/badge.svg)](https://github.com/martenframework/marten-smtp-emailing/actions)
[![CI](https://github.com/martenframework/marten-smtp-emailing/workflows/QA/badge.svg)](https://github.com/martenframework/marten-smtp-emailing/actions)

**Marten SMTP Emailing** provides an SMTP backend that can be used with Marten web framework's emailing system. 

## Installation

Simply add the following entry to your project's `shard.yml`:

```yaml
dependencies:
  marten_smtp_emailing:
    github: martenframework/marten-smtp-emailing
```

And run `shards install` afterward.

## Configuration

Once installed you can configure your project to use the SMTP backend by setting the corresponding configuration option as follows:

```crystal
Marten.configure do |config|
  config.emailing.backend = MartenSMTPEmailing::Backend.new
end
```

By default, the backend will attempt to deliver emails to an SMTP server running on localhost and listening on the standard SMTP port (25). If you need to, you can change these backend properties at initialization time:

```crystal
Marten.configure do |config|
  config.emailing.backend = MartenSMTPEmailing::Backend.new(
    host: "localhost",
    port: 25,
    helo_domain: "localhost",
    use_tls: true,
    username: nil,
    password: nil
  )
end
```

## Authors

Morgan Aubert ([@ellmetha](https://github.com/ellmetha)) and 
[contributors](https://github.com/martenframework/marten/contributors).

## License

MIT. See ``LICENSE`` for more details.
