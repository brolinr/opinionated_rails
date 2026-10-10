# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::AnswerShell do
  let(:base) { PromptShell.new("Stack" => "redis") }

  def shell(answers = {}, yes: false, base: self.base)
    described_class.new(base, answers: answers, yes: yes)
  end

  it "answers a prompt from its config key, matching on the label only" do
    expect(shell({ "app_type" => "api-only" }).ask("App type (default: Full-stack):")).to eq("api-only")
    expect(shell({ "stack" => "solid" }).ask("Stack (default: Solid):")).to eq("solid")
  end

  it "falls through to the wrapped shell for unanswered prompts" do
    expect(shell.ask("Stack (default: Solid):")).to eq("redis")
  end

  it "takes the default for unanswered prompts with yes: true" do
    expect(shell({}, yes: true).ask("Stack (default: Solid):")).to eq("")
  end

  it "still prefers a preset answer over yes" do
    expect(shell({ "stack" => "redis" }, yes: true).ask("Stack (default: Solid):")).to eq("redis")
  end

  it "converts booleans to yes/no" do
    s = shell({ "staging" => true, "vcr" => false })

    expect(s.ask("Add a staging environment? (default: no):")).to eq("yes")
    expect(s.ask("Enable VCR for HTTP interaction recording? (default: no):")).to eq("no")
  end

  it "maps Rails-style database names" do
    expect(shell({ "database" => "sqlite3" }).ask("Database (default: SQLite):")).to eq("sqlite")
    expect(shell({ "database" => "mysql2" }).ask("Database (default: SQLite):")).to eq("mysql")
    expect(shell({ "database" => "postgres" }).ask("Database (default: SQLite):")).to eq("postgresql")
  end

  it "accepts string or symbol keys" do
    expect(shell({ stack: "redis" }).ask("Stack (default: Solid):")).to eq("redis")
  end

  it "rejects unknown keys up front, listing the valid ones" do
    expect { shell({ "databse" => "postgresql" }) }
      .to raise_error(OpinionatedRails::Error, /Unknown option\(s\): databse.*Valid keys: .*database/)
  end

  it "raises instead of looping when a step re-asks because a preset value was rejected" do
    s = shell({ "app_name" => "9bad" }) # free text, so only the step can reject it
    s.ask("App name:")

    expect { s.ask("App name:") }.to raise_error(OpinionatedRails::Error, /Invalid value "9bad" for `app_name`/)
  end

  it "rejects a value outside a key's choices before anything runs, listing the choices" do
    expect { shell({ "database" => "oracle" }) }
      .to raise_error(OpinionatedRails::Error, /Invalid value "oracle" for `database`. Choose one of: sqlite, postgresql, mysql/)
    expect { shell({ "stack" => "redsi" }) }.to raise_error(OpinionatedRails::Error, /Choose one of: solid, redis/)
    expect { shell({ "staging" => "maybe" }) }.to raise_error(OpinionatedRails::Error, /Choose one of: yes, y, no, n/)
  end

  it "rejects a model name that is not a CamelCase constant" do
    expect { shell({ "auth_model" => "--force" }) }.to raise_error(OpinionatedRails::Error, /CamelCase/)
    expect { shell({ "auth_model" => "Account" }) }.not_to raise_error
  end

  it "accepts values case-insensitively" do
    expect(shell({ "test_framework" => "RSpec" }).ask("Test framework (default: Minitest):")).to eq("RSpec")
  end

  it "reports keys no prompt consumed" do
    s = shell({ "bundler" => "esbuild", "stack" => "redis" })
    s.ask("Stack (default: Solid):")

    expect(s.unused_keys).to eq([ "bundler" ])
  end

  it "delegates other shell methods" do
    s = shell
    s.say("hello")

    expect(base.messages).to eq([ "hello" ])
    expect(s).to respond_to(:say)
  end
end
