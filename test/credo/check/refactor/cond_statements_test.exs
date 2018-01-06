defmodule Credo.Check.Refactor.CondStatementsTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.CondStatements

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        cond do
          x < x -> -1
          x == x -> 0
          true -> 1
        end
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        cond do
          x == x -> 0
          true -> 1
        end
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation for multiple violations" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        cond do
          x == x -> 0
          true -> 1
        end
        cond do
          true -> 1
        end
      end
    end
    """
    |> to_source_file
    |> assert_issues(@described_check)
  end
end
