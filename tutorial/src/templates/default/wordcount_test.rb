def assert_equal(expected, input)
  actual = word_count(input)
  raise "Expected #{expected.inspect}, but got #{actual.inspect} for `#{input}`" unless expected == actual
  puts "`#{input}` — #{actual}: OK"
end

assert_equal 3, "one two three"

assert_equal 0, ""

assert_equal 1, "hello"

assert_equal 2, "hello   world "
