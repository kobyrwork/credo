defmodule Credo.Check.Consistency.SpaceInParentheses.CollectorTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.SpaceInParentheses.Collector

  @without_spaces """
  defmodule Credo.Sample1 do
    defmodule InlineModule do
      def foobar do
        {:ok} = File.read(filename)
        {
          :multi_line_tuple,
          File.read(filename) # completely fine
        }
      end
    end
  end
  """
  @with_spaces """
  defmodule Credo.Sample2 do
    defmodule InlineModule do
      def foobar do
        { :ok } = File.read( filename )
      end
    end
  end
  """

  @heredoc_example """
  string = ~s\"\"\"
  "[]"
  \"\"\"

  another_string = ~s\"\"\"
  "[ ]"
  \"\"\"
  """

  test "it should report correct frequencies" do
    without_spaces =
      @without_spaces
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{without_space: 2} == without_spaces

    with_spaces =
      @with_spaces
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{with_space: 1} == with_spaces
  end

  test "it should NOT report heredocs containing sigil chars" do
    values =
      @heredoc_example
      |> to_source_file
      |> Collector.collect_matches([])

    assert %{} == values
  end
end
