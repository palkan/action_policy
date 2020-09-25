# frozen_string_literal: true

module ActionPolicy
  # Adds `suggest` method which uses did_you_mean
  # to generate a suggestion message
  module SuggestMessage
    if defined?(::DidYouMean::SpellChecker)
      def suggest(needle, heystack)
        suggestion = ::DidYouMean::SpellChecker.new(
          dictionary: heystack
        ).correct(needle).first

        suggestion ? "\nDid you mean? #{suggestion}" : ""
      end
    else
      def suggest(*) = ""
    end
  end
end
