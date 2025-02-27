require_relative './helper'

return if not DidYouMean::TestHelper.ractor_compatible?

class RactorCompatibilityTest < Test::Unit::TestCase
  include DidYouMean::TestHelper

  class ::Book; end
  class FirstNameError < NameError; end

  def test_class_name_suggestion_works_in_ractor
    error = Ractor.new {
              begin
                Boook
              rescue NameError => e
                e.corrections # It is important to call the #corrections method within Ractor.
                e
              end
            }.take

    assert_correction "Book", error.corrections
  end

  def test_key_name_suggestion_works_in_ractor
    error = Ractor.new {
              begin
                hash = { "foo" => 1, bar: 2 }

                hash.fetch(:bax)
              rescue KeyError => e
                e.corrections # It is important to call the #corrections method within Ractor.
                e
              end
            }.take

    assert_correction ":bar", error.corrections
    assert_match "Did you mean?  :bar", error.to_s
  end

  def test_method_name_suggestion_works_in_ractor
    error = Ractor.new {
              begin
                self.to__s
              rescue NoMethodError => e
                e.corrections # It is important to call the #corrections method within Ractor.
                e
              end
            }.take

    assert_correction :to_s, error.corrections
    assert_match "Did you mean?  to_s",  error.to_s
  end

  if defined?(::NoMatchingPatternKeyError)
    def test_pattern_key_name_suggestion_works_in_ractor
      error = Ractor.new {
                begin
                  eval(<<~RUBY, binding, __FILE__, __LINE__)
                          hash = {foo: 1, bar: 2, baz: 3}
                          hash => {fooo:}
                          fooo = 1 # suppress "unused variable: fooo" warning
                  RUBY
                rescue NoMatchingPatternKeyError => e
                  e.corrections # It is important to call the #corrections method within Ractor.
                  e
                end
              }.take

      assert_correction ":foo", error.corrections
      assert_match "Did you mean?  :foo", error.to_s
    end
  end

  def test_can_raise_other_name_error_in_ractor
    error = Ractor.new {
      begin
        raise FirstNameError, "Other name error"
      rescue FirstNameError => e
        e.corrections # It is important to call the #corrections method within Ractor.
        e
      end
    }.take

    assert_not_match(/Did you mean\?/, error.message)
  end

  def test_variable_name_suggestion_works_in_ractor
    error = Ractor.new {
      in_ractor = in_ractor = 1

      begin
        in_reactor
      rescue NameError => e
        e.corrections # It is important to call the #corrections method within Ractor.
        e
      end
    }.take

    assert_correction :in_ractor, error.corrections
    assert_match "Did you mean?  in_ractor", error.to_s
  end
end
