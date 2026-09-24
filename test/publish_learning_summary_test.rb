# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require "tempfile"
require_relative "../scripts/publish_learning_summary"

module SummaryFixture
  def valid_summary
    {
      "session" => { "topic" => "React state management" },
      "learned" => ["Derived values do not always need component state"],
      "practiced" => ["Refactored OrderSummary"],
      "difficulties" => ["Still unsure when memoization is useful"],
      "support" => {
        "needed" => true,
        "question" => "Could a senior developer review this decision?"
      }
    }
  end

  def problems_for(summary)
    SummaryValidator.new(summary).problems
  end

  def payload_for(summary = valid_summary, mentor_handle: nil, learner_name: "Jane Doe")
    SlackMessage.new(
      summary: summary,
      learner_name: learner_name,
      date: "2026-09-23",
      mentor_handle: mentor_handle
    ).payload
  end

  def with_summary_file(content = JSON.generate(valid_summary))
    Tempfile.create(["learning-summary", ".json"]) do |file|
      file.write(content)
      file.flush
      yield file.path
    end
  end
end

class SummaryValidatorTest < Minitest::Test
  include SummaryFixture

  def test_accepts_valid_summary
    assert_empty problems_for(valid_summary)
  end

  def test_reports_required_contract_problems_together
    summary = {
      "session" => {},
      "learned" => [],
      "practiced" => "refactoring",
      "difficulties" => [" "],
      "support" => {}
    }
    problems = problems_for(summary).join("\n")

    assert_includes problems, "session.topic"
    assert_includes problems, "learned must contain at least one item"
    assert_includes problems, "practiced is required and must be an array"
    assert_includes problems, "difficulties must contain only non-blank strings"
    assert_includes problems, "support.needed"
  end

  def test_requires_question_only_when_support_is_needed
    needed = valid_summary.merge("support" => { "needed" => true })
    not_needed = valid_summary.merge("support" => { "needed" => false })

    assert_includes problems_for(needed).join, "support.question"
    assert_empty problems_for(not_needed)
  end
end

class SlackMessageTest < Minitest::Test
  include SummaryFixture

  def test_builds_readable_payload_and_drops_empty_sections
    summary = valid_summary.merge(
      "practiced" => [],
      "difficulties" => [],
      "support" => { "needed" => false }
    )
    rendered = JSON.generate(payload_for(summary))

    assert_includes rendered, "React state management"
    assert_includes rendered, "Derived values"
    assert_includes rendered, "Support needed:* No"
    refute_includes rendered, "Practiced"
    refute_includes rendered, "Still difficult"
  end

  def test_mentions_only_a_valid_mentor_when_support_is_needed
    valid = JSON.generate(payload_for(mentor_handle: "<!subteam^S123>"))
    invalid = JSON.generate(payload_for(mentor_handle: "@channel"))

    assert_includes valid, "<!subteam^S123>"
    refute_includes invalid, "@channel"
  end

  def test_escapes_learner_content_and_ignores_unknown_fields
    summary = valid_summary.merge(
      "session" => { "topic" => "Ping <@U999>" },
      "learned" => ["Use A & B"],
      "conversation" => "private conversation"
    )
    rendered = JSON.generate(payload_for(summary))

    assert_includes rendered, "&lt;@U999&gt;"
    assert_includes rendered, "A &amp; B"
    refute_includes rendered, "private conversation"
  end

  def test_rejects_any_rendered_section_over_slack_limit
    long_text = "&" * 601
    long_learned = valid_summary.merge("learned" => [long_text])
    long_support = valid_summary.merge(
      "support" => { "needed" => true, "question" => long_text }
    )

    assert_raises(PublishError) { payload_for(long_learned) }
    assert_raises(PublishError) { payload_for(long_support) }
    assert_raises(PublishError) { payload_for(valid_summary, learner_name: long_text) }
  end
end

class SlackPublisherTest < Minitest::Test
  def test_accepts_official_slack_webhook_hosts
    %w[hooks.slack.com hooks.slack-gov.com].each do |host|
      publisher = SlackPublisher.new("https://#{host}/services/T000/B000/SECRET")

      assert_equal host, publisher.send(:parse_webhook).host
    end
  end

  def test_rejects_unsafe_webhook_urls
    urls = [
      "http://hooks.slack.com/services/example",
      "https://example.com/services/example",
      "https://attacker@hooks.slack.com/services/example"
    ]

    urls.each do |url|
      assert_raises(PublishError) { SlackPublisher.new(url).publish(text: "hello") }
    end
  end

  def test_sanitizes_network_errors
    webhook = "https://hooks.slack.com/services/T000/B000/SECRET"
    error = RuntimeError.new("failed to open #{webhook}")
    message = SlackPublisher.new(webhook).sanitize_error(error)

    assert_includes message, "RuntimeError"
    refute_includes message, webhook
    refute_includes message, "SECRET"
  end
end

class CliTest < Minitest::Test
  include SummaryFixture

  def test_default_mode_previews_without_a_webhook
    with_summary_file do |path|
      out = StringIO.new
      err = StringIO.new

      status = main(
        [path],
        out: out,
        err: err,
        env: { LEARNER_ENV => "Jane Doe" },
        now: Time.new(2026, 9, 23)
      )

      assert_equal 0, status
      assert_empty err.string
      assert_includes out.string, "DRY RUN"
      assert_includes out.string, "nothing was sent"
    end
  end

  def test_requires_learner_name
    with_summary_file do |path|
      out = StringIO.new
      err = StringIO.new

      status = main([path], out: out, err: err, env: {})

      assert_equal 1, status
      assert_includes err.string, LEARNER_ENV
    end
  end

  def test_send_requires_webhook
    with_summary_file do |path|
      out = StringIO.new
      err = StringIO.new

      status = main(
        [path, "--send"],
        out: out,
        err: err,
        env: { LEARNER_ENV => "Jane Doe" }
      )

      assert_equal 1, status
      assert_includes err.string, WEBHOOK_ENV
    end
  end

  def test_reports_invalid_json
    with_summary_file("not-json") do |path|
      err = StringIO.new

      status = main([path], out: StringIO.new, err: err, env: {})

      assert_equal 1, status
      assert_includes err.string, "not valid JSON"
    end
  end
end
