require 'anthropic'

# Claude adapter for Lab::Ai. Implements the one method an adapter needs:
#
#   json(system:, prompt:, schema:, effort:) -> Hash, or nil on any failure
#
# A ChatGPT adapter would be a sibling class with the same method, selected by
# LAB_AI_PROVIDER. Nothing outside app/lib/lab/ai/ knows which provider is in use.
module Lab
  module Ai
    class Claude
      MODEL = 'claude-opus-5-5'

      def initialize(api_key)
        @client = Anthropic::Client.new(api_key: api_key, timeout: 90, max_retries: 2)
      end

      def name
        "Claude (#{MODEL})"
      end

      def json(system:, prompt:, schema:, effort: :low)
        message = @client.beta.messages.create(
          model: MODEL,
          max_tokens: 16_000,
          system_: system,
          messages: [{ role: 'user', content: prompt }],
          output_config: { effort: effort, format_: { type: :json_schema, schema: schema } },
          # If the model declines on policy grounds, let the server retry on its
          # default fallback model rather than failing the request outright.
          fallbacks: :default,
          betas: ['server-side-fallback-2026-07-01']
        )
        unless message.stop_reason == :end_turn
          Rails.logger.warn("Lab::Ai::Claude stop_reason=#{message.stop_reason} #{message.stop_details&.category}")
          return nil
        end
        text = message.content.select { |b| b.type == :text }.map(&:text).join
        JSON.parse(text)
      rescue JSON::ParserError => e
        Rails.logger.error("Lab::Ai::Claude unparseable output: #{e.message}")
        nil
      rescue Anthropic::Errors::AuthenticationError, Anthropic::Errors::PermissionDeniedError => e
        Rails.logger.error("Lab::Ai::Claude credentials rejected (#{e.class}) - check anthropic.api_key")
        nil
      rescue Anthropic::Errors::RateLimitError => e
        Rails.logger.warn("Lab::Ai::Claude rate limited after retries: #{e.message}")
        nil
      rescue Anthropic::Errors::APIStatusError => e
        Rails.logger.error("Lab::Ai::Claude API error #{e.status}: #{e.message}")
        nil
      rescue Anthropic::Errors::APIConnectionError => e
        Rails.logger.error("Lab::Ai::Claude connection failed: #{e.message}")
        nil
      end
    end
  end
end
