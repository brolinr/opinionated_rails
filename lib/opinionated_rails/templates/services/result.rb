# frozen_string_literal: true

class Result
  attr_reader :errors, :data, :status

  def self.failure(*errors, status: :unprocessable_entity)
    new(errors: errors, status: status)
  end

  def self.success(data = nil, status: :ok)
    new(data: data, status: status)
  end

  def initialize(errors: [], data: nil, status: nil)
    @errors = Array(errors)
    @data = data
    @status = status
  end

  def assign_data(object)
    @data = object
  end

  def add_error(message, status_name = nil)
    @status = status_name || :unprocessable_entity
    if message.is_a?(Array)
      @errors += message
    else
      @errors << message
    end
  end

  def success?
    if errors.blank?
      @status = :ok
      return true
    end
    false
  end

  def failure?
    errors.present? || status == :unprocessable_entity
  end

  def error_string
    errors.compact.join(' ')
  end
end
