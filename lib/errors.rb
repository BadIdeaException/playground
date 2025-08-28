# frozen_string_literal: true

module Errors
  class PlaygroundExistsError < StandardError
  end

  class PlaygroundNotFoundError < StandardError
  end

  class TemplateNotFoundError < StandardError
  end
end
