# frozen_string_literal: true

require "spec_helper"

# The slow suite's helpers decide what environment a generated app is booted with. A wrong URL here
# fails a combo for a reason that has nothing to do with the generator (a MySQL app was once given a
# sqlite3 URL), so the mapping is pinned.
RSpec.describe GeneratedApp do
  include GeneratedApp

  def url_for(adapter_text)
    Dir.mktmpdir do |app|
      FileUtils.mkdir_p(File.join(app, "config"))
      File.write(File.join(app, "config/database.yml"), "default: &default\n  adapter: #{adapter_text}\n")
      production_env(app)["DATABASE_URL"]
    end
  end

  it "uses a database URL that matches the app's adapter" do
    expect(url_for("postgresql")).to start_with("postgresql://")
    expect(url_for("mysql2")).to start_with("mysql2://")
    expect(url_for("sqlite3")).to start_with("sqlite3://")
  end

  it "always provides a Redis URL for the Redis stack's production boot" do
    Dir.mktmpdir do |app|
      FileUtils.mkdir_p(File.join(app, "config"))
      File.write(File.join(app, "config/database.yml"), "adapter: sqlite3\n")

      expect(production_env(app)["REDIS_URL"]).to eq("redis://localhost:6379/1")
    end
  end
end
