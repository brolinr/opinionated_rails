# frozen_string_literal: true

class ApplicationService
  def self.call(params: {}, context: {}, **args)
    new(params: params, context: context).call(**args)
  end

  attr_reader :result, :params, :context

  def initialize(params: {}, context: {})
    @params = params
    @context = context
    @result = Result.new
  end

  delegate :assign_data, to: :result
  delegate :add_error, to: :result
  delegate :success?, to: :result
  delegate :failure?, to: :result
  alias add_errors add_error

  def step(method)
    return unless success?

    send(method)
  end

  def preload(*methods)
    methods.map { |method| send(method) }
  end

  def call
    raise NotImplementedError, '#call method must be implemented'
  end

  def transaction
    ActiveRecord::Base.transaction do
      yield
      raise ActiveRecord::Rollback unless success?
    end
  rescue ActiveRecord::Rollback => e
    # it just returns a message, the errors are already added to use_case
    add_error(e.message)
  end

  ## Setup solidqueue first
  # def self.call_async(params: {}, context: {})
  #   AsyncJob.perform_later(name, params, context)
  # end
end
