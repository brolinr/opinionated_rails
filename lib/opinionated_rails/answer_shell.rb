# frozen_string_literal: true

module OpinionatedRails
  # Wraps the interactive shell so prompts can be answered from flags or a config file.
  # Unanswered prompts fall through to the wrapped shell, or take their default with `yes: true`.
  # A preset answer that a step rejects raises instead of re-prompting forever.
  class AnswerShell
    # config key => text found in the prompt label (the part before "(default")
    LABELS = {
      "app_name" => "App name",
      "database" => "Database",
      "app_type" => "App type",
      "test_framework" => "Test framework",
      "frontend" => "Frontend",
      "bundler" => "Bundler",
      "rubocop" => "RuboCop style",
      "stack" => "Stack",
      "pagination" => "Pagination",
      "staging" => "staging environment",
      "services" => "application service",
      "secrets" => "Secrets handling",
      "auth_model" => "User model name",
      "auth" => "Authentication",
      "factory" => "Factory strategy",
      "vcr" => "VCR",
      "js_lint" => "JS linting",
      "kamal" => "Kamal",
      "ci" => "CI workflow",
      "mailer" => "mailer"
    }.freeze

    VALUE_ALIASES = {
      "database" => { "sqlite3" => "sqlite", "postgres" => "postgresql", "pg" => "postgresql", "mysql2" => "mysql" },
      "secrets" => { "credentials" => "rails_credentials" }
    }.freeze

    YES_NO = %w[ yes y no n ].freeze

    # Accepted values per key, checked before anything is generated so a typo fails immediately
    # instead of after `rails new` has already run. A spec keeps this in step with the steps' prompts.
    CHOICES = {
      "database" => %w[ sqlite postgresql mysql ],
      "app_type" => %w[ full-stack api-only ],
      "test_framework" => %w[ minitest rspec ],
      "frontend" => %w[ stimulus stimulus+hotwire react ],
      "bundler" => %w[ esbuild bun webpack ],
      "rubocop" => %w[ omakase custom ],
      "stack" => %w[ solid redis ],
      "pagination" => %w[ pagy geared_pagination ],
      "secrets" => %w[ rails_credentials rails\ credentials dotenv ],
      "auth" => %w[ none rails8 devise ],
      "factory" => %w[ factorybot factory_bot fixtures ],
      "staging" => YES_NO, "services" => YES_NO, "vcr" => YES_NO, "js_lint" => YES_NO,
      "kamal" => YES_NO, "ci" => YES_NO, "mailer" => YES_NO
    }.freeze

    MODEL_NAME = /\A[A-Z][A-Za-z0-9]*\z/

    attr_reader :used

    def initialize(base, answers: {}, yes: false)
      @base = base
      @yes = yes
      @answers = normalize(answers)
      @used = Hash.new(0)
    end

    def ask(prompt = nil, *args)
      key = key_for(prompt)

      if key && @answers.key?(key)
        @used[key] += 1
        raise Error, invalid_message(key, prompt) if @used[key] > 1

        return @answers[key]
      end

      return "" if @yes

      @base.ask(prompt, *args)
    end

    # Config keys that no prompt consumed (e.g. `bundler` for a Stimulus app).
    def unused_keys
      @answers.keys - @used.keys
    end

    def respond_to_missing?(name, include_private = false)
      @base.respond_to?(name, include_private) || super
    end

    def method_missing(name, *args, &block)
      return super unless @base.respond_to?(name)

      @base.public_send(name, *args, &block)
    end

    private

    def key_for(prompt)
      label = prompt.to_s.split("(default").first.downcase
      LABELS.find { |_, text| label.include?(text.downcase) }&.first
    end

    def normalize(answers)
      unknown = answers.keys.map(&:to_s) - LABELS.keys
      raise Error, "Unknown option(s): #{unknown.join(', ')}. Valid keys: #{LABELS.keys.join(', ')}" unless unknown.empty?

      answers.each_with_object({}) do |(key, value), result|
        key = key.to_s
        value = value == true ? "yes" : value == false ? "no" : value.to_s.strip
        result[key] = VALUE_ALIASES.fetch(key, {}).fetch(value.downcase, value)
        validate_value!(key, result[key])
      end
    end

    def validate_value!(key, value)
      choices = CHOICES[key]
      if choices && !choices.include?(value.downcase)
        raise Error, "Invalid value #{value.inspect} for `#{key}`. Choose one of: #{choices.join(', ')}"
      end
      return unless key == "auth_model" && !MODEL_NAME.match?(value)

      raise Error, "Invalid value #{value.inspect} for `auth_model`. Use a CamelCase constant such as User or Account."
    end

    def invalid_message(key, prompt)
      "Invalid value #{@answers[key].inspect} for `#{key}` (#{prompt.to_s.strip})"
    end
  end
end
