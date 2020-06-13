# ActionClient

Make HTTP calls by leveraging Rails rendering

## This project is in its early phases of development

Its interface, behavior, and name are likely to change drastically before being
published to RubyGems. Use at your own risk.

## Usage

Considering a hypothetical scenario where we need to make a [`POST`
request][mdn-post] to `https://example.com/articles` with a JSON payload of `{
"title": "Hello, World" }`.

First, declare the `ArticlesClient` as a descendant of `ActionClient::Base`:

```ruby
class ArticlesClient < ActionClient::Base
end
```

Next, declare the request method. In this case, the semantics are similar to
[Rails' existing controller naming conventions][naming-actions], so let's lean
into that by declaring the `create` action so that it accepts a `title:` option:

```ruby
class ArticlesClient < ActionClient::Base
  def create(title:)
  end
end
```

Our client action will need to make an [HTTP `POST` request][mdn-post] to
`https://example.com/articles`, so let's declare that call:

```ruby
class ArticlesClient < ActionClient::Base
  def create(title:)
    post url: "https://example.com/articles"
  end
end
```

The request will need a payload for its body, so let's declare the template as
`app/views/articles_client/create.json.erb`:

```json+erb
{ "title": <%= @title %> }
```

Since the template needs access to the `@title` instance variable, update the
client's request action to declare it:

```ruby
class ArticlesClient < ActionClient::Base
  def create(title:)
    @title = "Hello, World"

    post url: "https://example.com/articles"
  end
end
```

By default, `ActionClient` will deduce the request's [`Content-Type:
application/json` HTTP header][mdn-content-type] based on the format of the
action's template. In this case, since we've declared `.json.erb`, the
`Content-Type` will be set to `application/json`. The same would be true for a
template named `create.json.jbuilder`.

If we were to declare the template as `create.xml.erb` or `create.xml.builder`,
the `Content-Type` header would be set to `application/xml`.

Finally, it's time to submit the request. In the application code that needs to
make the HTTP call, invoke the `#submit` method:

```ruby
status, headers, body = ArticlesClient.create(title: "Hello, World").submit
```

The `#submit` call processes the request through a stack of [Rack
middleware][rack], and returns the request in adherence to the [Rack response
specifications][rack-response], namely in a triple of its HTTP Status Code, the
response Headers, and the response Body.

When `ActionClient` is able to infer the request's `Content-Type` to be either
`JSON` or `XML`, it will parse the returned `body` value ahead of time.

Requests make with `application/json` will be parsed into [`Hash`
instances][ruby-hash] by [`JSON.parse`][json-parse]. JSON objects will be parsed
into instances of [`HashWithIndifferentAccess`][HashWithIndifferentAccess], so
that keys can be accessed via `Symbol` or  `String`.

Requests made with `application/xml` will be parsed into
[`Nokogiri::XML::Document` instances][nokogiri-document] by
[`Nokogiri::XML`][nokogiri-xml].

If the response body is invalid JSON or XML, the original `body` will be
returned, unmodified.

[mdn-post]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST
[naming-actions]: https://guides.rubyonrails.org/action_controller_overview.html#methods-and-actions
[mdn-content-type]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type
[rack]: https://github.com/rack/rack
[rack-response]: https://github.com/rack/rack/blob/master/SPEC.rdoc#the-response-
[json-parse]: https://ruby-doc.org/stdlib-2.6.3/libdoc/json/rdoc/JSON.html#method-i-parse
[HashWithIndifferentAccess]: https://api.rubyonrails.org/classes/ActiveSupport/HashWithIndifferentAccess.html
[ruby-hash]: https://ruby-doc.org/core-2.7.1/Hash.html
[nokogiri-xml]: https://nokogiri.org/rdoc/Nokogiri.html#XML-class_method
[nokogiri-document]: https://nokogiri.org/rdoc/Nokogiri/XML/Document.html

### Query Parameters

To set a request's query parameters, pass them a `Hash` under the `query:`
option:

```ruby
class ArticlesClient < ActionClient::Base
  def all(search_term:)
    get url: "https://examples.com/articles", query: { q: search_term }
  end
end
```

You can also pass query parameters directly as part of the `url:` or `path:`
option:

```ruby
class ArticlesClient < ActionClient::Base
  default url: "https://examples.com"

  def all(search_term:, **query_parameters)
    get path: "/articles?q={search_term}", query: query_parameters
  end
end
```

When a key-value pair exists in both the `path:` (or `url:`) option and `query:`
option, the value present in the URL will be overridden by the `query:` value.

### Configuration

Descendants of `ActionClient::Base` can specify some defaults:

```ruby
class ArticlesClient < ActionClient::Base
  default url: "https://example.com"
  default headers: { "Content-Type": "application/json" }
end
```

Default values can be overridden on a request-by-request basis.

When a default `url:` key is specified, a request's full URL will be built by
joining the base `default url: ...` value with the request's `path:` option.

### Previews

Inspired by [`ActionMailer::Previews`][action_mailer_previews], you can view
previews for an exemplary outbound HTTP request:

```ruby
# test/clients/previews/articles_client_preview.rb
class ArticlesClientPreview < ActionClient::Preview
  def create
    ArticlesClient.create(title: "Hello, from Previews!")
  end
end
```

To view the URL, headers and payload that would be generated by that request,
visit
<http://localhost:3000/rails/action_client/clients/articles_client/create>.

Each request's preview page also include a copy-pastable, terminal-ready [`cURL`
command][curl].

[action_mailer_previews]: https://guides.rubyonrails.org/action_mailer_basics.html#previewing-emails
[curl]: https://curl.haxx.se/

## Installation
Add this line to your application's Gemfile:

```ruby
gem "action_client", github: "thoughtbot/action_client"
```

And then execute:
```bash
$ bundle
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
