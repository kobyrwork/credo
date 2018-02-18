defmodule Credo.Check.Readability.ModuleDoc do
  @moduledoc """
  Every module should contain comprehensive documentation.

      # preferred

      defmodule MyApp.Web.Search do
        @moduledoc \"\"\"
        This module provides a public API for all search queries originating
        in the web layer.
        \"\"\"
      end

      # also okay: explicitly say there is no documentation

      defmodule MyApp.Web.Search do
        @moduledoc false
      end

  Many times a sentence or two in plain english, explaining why the module
  exists, will suffice. Documenting your train of thought this way will help
  both your co-workers and your future-self.

  Other times you will want to elaborate even further and show some
  examples of how the module's functions can and should be used.

  In some cases however, you might not want to document things about a module,
  e.g. it is part of a private API inside your project. Since Elixir prefers
  explicitness over implicit behaviour, you should "tag" these modules with

      @moduledoc false

  to make it clear that there is no intention in documenting it.
  """

  @explanation [
    check: @moduledoc,
    params: [
      ignore_names: "All modules matching this regex (or list of regexes) will be ignored."
    ]
  ]
  @default_params [
    ignore_names: [
      ~r/(\.\w+Controller|\.Endpoint|\.Repo|\.Router|\.\w+Socket|\.\w+View)$/
    ]
  ]

  alias Credo.Code.Module

  use Credo.Check

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    if Path.extname(filename) == ".exs" do
      []
    else
      issue_meta = IssueMeta.for(source_file, params)
      ignore_names = Params.get(params, :ignore_names, @default_params)

      {_continue, issues} =
        Credo.Code.prewalk(
          source_file,
          &traverse(&1, &2, issue_meta, ignore_names),
          {true, []}
        )

      issues
    end
  end

  defp traverse(
         {:defmodule, meta, _arguments} = ast,
         {true, issues},
         issue_meta,
         ignore_names
       ) do
    mod_name = Module.name(ast)

    if CodeHelper.matches?(mod_name, ignore_names) do
      {ast, {false, issues}}
    else
      exception? = Module.exception?(ast)

      case Module.attribute(ast, :moduledoc) do
        {:error, _} when not exception? ->
          {
            ast,
            {true, [issue_for(issue_meta, meta[:line], mod_name)] ++ issues}
          }

        _ ->
          {ast, {true, issues}}
      end
    end
  end

  defp traverse(ast, {continue, issues}, _issue_meta, _ignore_names) do
    {ast, {continue, issues}}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Modules should have a @moduledoc tag.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
