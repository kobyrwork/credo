defmodule Credo.Test.CheckRunnerTest do
  use Credo.TestHelper

  import Credo.Test.CheckRunner

  alias Credo.Issue
  alias Credo.SourceFile

  @source_file %SourceFile{filename: "x"}

  defmodule FakeTestCheck do
    use Credo.Check

    def run(source_file, params \\ []) do
      if params[:issue_count] do
        issue_count = params[:issue_count] || 0

        replicate(issue_count, %Issue{filename: source_file.filename})
      else
        []
      end
    end

    defp replicate(count, item) do
      for(_ <- 1..count, do: item)
    end
  end

  test "it should run the check" do
    issues = run_check(@source_file, FakeTestCheck, [])

    assert issues == []
  end

  test "it should run the check /2" do
    issues = run_check(@source_file, FakeTestCheck, issue_count: 1)

    assert Enum.count(issues) == 1
  end

  test "it should run the check /3" do
    issues = run_check(@source_file, FakeTestCheck, issue_count: 3)

    assert Enum.count(issues) == 3
  end
end
