defmodule Credo.Check.Design.TagFIXMETest do
  use Credo.TestHelper

  @described_check Credo.Check.Design.TagFIXME

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    assert x == x + 2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report an issue" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case # TODO: this should not appear in the FIXME test

  # FIXME: this should not appear in the # FIXME test

  def some_fun do
    assert x == x + 2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report an issue when lower case" do
"""
defmodule CredoSampleModule do
  def some_fun do
    # fixme blah blah
    Repo.preload(:comments)
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a couple of issues" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case # FIXME: this is the first
  @moduledoc \"\"\"
    this is an example # FIXME: and this is no actual comment
  \"\"\"

  def some_fun do # FIXME this is the second
    x = ~s{also: # FIXME: no comment here}
    assert 2 == x
    ?" # FIXME: this is the third

    "also: # FIXME: no comment here as well"
  end
end
""" |> to_source_file
    |> assert_issues(@described_check, fn(issues) ->
        assert 3 == Enum.count(issues)
      end)
  end

end
