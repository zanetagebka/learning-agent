#!/usr/bin/env ruby
# frozen_string_literal: true

# Preview or publish a privacy-limited learning summary.
#
#   ruby learning-agent/scripts/publish_learning_summary.rb path/to/summary.json
#   ruby learning-agent/scripts/publish_learning_summary.rb path/to/summary.json --send
#
# Preview is the default. The webhook is read only in explicit --send mode.

require "json"
require "net/http"
require "uri"

WEBHOOK_ENV = "SLACK_LEARNING_WEBHOOK_URL"
MENTOR_ENV = "SLACK_MENTOR_HANDLE"
LEARNER_ENV = "LEARNER_NAME"

class PublishError < StandardError; end

module SlackText
  module_function

  def escape(value)
    value.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end
end

class SummaryValidator
  LIST_KEYS = %w[learned practiced difficulties].freeze

  def initialize(summary)
    @summary = summary
  end

  def problems
    return ["summary must be a JSON object"] unless summary.is_a?(Hash)

    [
      topic_problem,
      *LIST_KEYS.flat_map { |key| list_problems(key) },
      *support_problems
    ].compact
  end

  private

  attr_reader :summary

  def topic_problem
    session = summary["session"]
    return if session.is_a?(Hash) && present_string?(session["topic"])

    "session.topic is required and must be a non-blank string"
  end

  def list_problems(key)
    value = summary[key]
    return ["#{key} is required and must be an array"] unless value.is_a?(Array)

    problems = []
    problems << "learned must contain at least one item" if key == "learned" && value.empty?
    problems << "#{key} must contain only non-blank strings" unless value.all? { |item| present_string?(item) }
    problems
  end

  def support_problems
    support = summary["support"]
    return ["support is required and must be an object"] unless support.is_a?(Hash)

    needed = support["needed"]
    return ["support.needed is required and must be true or false"] unless [true, false].include?(needed)

    return [] unless needed
    return [] if present_string?(support["question"])

    ["support.question is required when support.needed is true"]
  end

  def present_string?(value)
    value.is_a?(String) && !value.strip.empty?
  end
end

class SlackMessage
  MENTION_PATTERN = /\A(?:<@[UW][A-Z0-9]+>|<!subteam\^[A-Z0-9]+>)\z/
  MAX_SECTION_TEXT_LENGTH = 3_000

  def initialize(summary:, learner_name:, date:, mentor_handle: nil)
    @summary = summary
    @learner_name = learner_name
    @date = date
    @mentor_handle = mentor_handle
  end

  def payload
    { text: fallback_text, blocks: blocks }
  end

  private

  attr_reader :summary, :learner_name, :date, :mentor_handle

  def fallback_text
    base = "Learning session: #{SlackText.escape(topic)} — #{SlackText.escape(learner_name)}"
    support_needed? ? "#{base} (support needed)" : base
  end

  def blocks
    [
      section("*🎓  #{SlackText.escape(topic)}*\n#{SlackText.escape(learner_name)} · #{SlackText.escape(date)}"),
      bullets("Learned", summary["learned"]),
      bullets("Practiced", summary["practiced"]),
      bullets("Still difficult", summary["difficulties"]),
      support_block
    ].compact
  end

  def bullets(title, items)
    return nil if items.empty?

    section("*#{title}*\n#{items.map { |item| "• #{SlackText.escape(item)}" }.join("\n")}")
  end

  def support_block
    return section("*Support needed:* No") unless support_needed?

    heading = "*Support needed*"
    heading += " — cc #{mentor_handle}" if valid_mention?
    section("#{heading}\n> #{SlackText.escape(summary.dig('support', 'question'))}")
  end

  def topic
    summary.dig("session", "topic")
  end

  def support_needed?
    summary.dig("support", "needed") == true
  end

  def valid_mention?
    mentor_handle.to_s.match?(MENTION_PATTERN)
  end

  def section(text)
    if text.length > MAX_SECTION_TEXT_LENGTH
      raise PublishError, "Slack section exceeds #{MAX_SECTION_TEXT_LENGTH} characters"
    end

    { type: "section", text: { type: "mrkdwn", text: text } }
  end
end

class SlackPublisher
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 10
  ALLOWED_WEBHOOK_HOSTS = %w[hooks.slack.com hooks.slack-gov.com].freeze

  def initialize(webhook_url)
    @webhook_url = webhook_url
  end

  def publish(payload)
    uri = parse_webhook
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(payload)

    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    ) { |http| http.request(request) }

    return true if response.code == "200"

    body = response.body.to_s.strip[0, 200]
    raise PublishError, "Slack rejected the message (HTTP #{response.code}): #{body}"
  rescue PublishError
    raise
  rescue StandardError => e
    raise PublishError, sanitize_error(e)
  end

  def sanitize_error(exception)
    "#{exception.class}: Slack request failed; webhook details redacted"
  end

  private

  attr_reader :webhook_url

  def parse_webhook
    uri = URI.parse(webhook_url)
    valid = uri.scheme == "https" &&
            ALLOWED_WEBHOOK_HOSTS.include?(uri.host.to_s.downcase) &&
            uri.userinfo.nil?
    return uri if valid

    raise PublishError, allowed_webhook_error
  rescue URI::InvalidURIError
    raise PublishError, allowed_webhook_error
  end

  def allowed_webhook_error
    "Slack webhook must use HTTPS on #{ALLOWED_WEBHOOK_HOSTS.join(' or ')}"
  end
end

def load_summary(path)
  JSON.parse(File.read(path))
rescue JSON::ParserError => e
  raise PublishError, "#{path} is not valid JSON: #{e.message}"
rescue SystemCallError => e
  raise PublishError, "Cannot read #{path}: #{e.message}"
end

def validate_summary!(path, summary)
  problems = SummaryValidator.new(summary).problems
  return if problems.empty?

  details = problems.map { |problem| "  - #{problem}" }.join("\n")
  raise PublishError, "#{path} is not a valid learning summary:\n#{details}"
end

def main(argv, out: $stdout, err: $stderr, env: ENV, now: Time.now)
  args = argv.dup
  send_requested = !args.delete("--send").nil?
  path = args.shift

  if path.nil? || !args.empty?
    err.puts "Usage: ruby #{$PROGRAM_NAME} <path-to-summary.json> [--send]"
    return 1
  end

  summary = load_summary(path)
  validate_summary!(path, summary)

  learner_name = env.fetch(LEARNER_ENV, nil).to_s.strip
  raise PublishError, "No learner name. Set #{LEARNER_ENV}." if learner_name.empty?

  payload = SlackMessage.new(
    summary: summary,
    learner_name: learner_name,
    date: now.strftime("%Y-%m-%d"),
    mentor_handle: env.fetch(MENTOR_ENV, nil)
  ).payload

  unless send_requested
    out.puts "DRY RUN — nothing was sent"
    out.puts JSON.pretty_generate(payload)
    out.puts "Approve this exact payload, then rerun with --send."
    return 0
  end

  webhook = env.fetch(WEBHOOK_ENV, nil)
  raise PublishError, "#{WEBHOOK_ENV} is not set." if webhook.to_s.strip.empty?

  SlackPublisher.new(webhook).publish(payload)
  out.puts "Published learning summary to Slack."
  0
rescue PublishError => e
  err.puts e.message
  1
end

exit(main(ARGV)) if __FILE__ == $PROGRAM_NAME
