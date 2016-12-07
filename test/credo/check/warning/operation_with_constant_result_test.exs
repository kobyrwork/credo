defmodule Credo.Check.Warning.OperationWithConstantResultTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.OperationWithConstantResult

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    x * 2
    Enum.reject(some_list, &is_nil/1)
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation for * 1" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    x * 1
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation for all defined operations" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun(x, y) do
    x * 1   # always returns x
    x * 0   # always returns 0
  end
end
""" |> to_source_file
    |> assert_issues(@described_check, fn(issues) ->
        assert 2 == Enum.count(issues), "found: #{to_inspected(issues)}"
      end)
  end

end
