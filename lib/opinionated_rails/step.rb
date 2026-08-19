# frozen_string_literal: true

module OpinionatedRails
  class Step
    def self.id
      raise NotImplementedError, "#{name}#id not implemented"
    end

    def self.tier
      :addon
    end

    def self.needs
      []
    end

    def if_condition(_context)
      true
    end

    def prompt(_context)
      raise NotImplementedError, "#{self.class}#prompt not yet implemented"
    end

    def generate(_context)
      raise NotImplementedError, "#{self.class}#generate not yet implemented"
    end

    def outputs(_context)
      raise NotImplementedError, "#{self.class}#outputs not yet implemented"
    end
  end
end
