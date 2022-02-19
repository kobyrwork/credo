defmodule Credo.Check.Warning.IgnoredLoggerMetadata do
  @moduledoc """
  Check to avoid ignoring Logger metadata in your logger config
  """
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [
      ignore: [:debug],
      allowed_metadata: []
    ],
    explanations: [
      check: """
      Ensures custom metadata keys are included in logger config

      Note that all metadata is optional and may not always be available.

      For example, you might wish to include a custom `:error_code` metadata in your logs:

          Logger.error("We have a problem", [error_code: :pc_load_letter])

      In your app's logger configuration, you would need to include the `:error_code` key:

          config :logger, :console,
            format: "[$level] $message $metadata\n",
            metadata: [:error_code, :file]

      """,
      params: [
        ignore: "Do not raise an issue for these Logger calls.",
        allowed_metadata: "Do not raise an issue for these metadata keys"
      ]
    ]

  @logger_functions ~w(alert critical debug emergency error info notice warn warning metadata log)a

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    state = {false, []}

    {_, issues} = Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta), state)

    issues
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:Logger]}, fun_name]}, meta, arguments} = ast,
         state,
         issue_meta
       )
       when fun_name in @logger_functions do
    issue = find_issue(fun_name, arguments, meta, issue_meta)

    {ast, add_issue_to_state(state, issue)}
  end

  defp traverse(
         {fun_name, meta, arguments} = ast,
         {true, _issues} = state,
         issue_meta
       )
       when fun_name in @logger_functions do
    issue = find_issue(fun_name, arguments, meta, issue_meta)

    {ast, add_issue_to_state(state, issue)}
  end

  defp traverse(
         {:import, _meta, arguments} = ast,
         {_module_contains_import?, issues} = state,
         _issue_meta
       ) do
    if logger_import?(arguments) do
      {ast, {true, issues}}
    else
      {ast, state}
    end
  end

  defp traverse(ast, state, _issue_meta) do
    {ast, state}
  end

  defp add_issue_to_state(state, nil), do: state

  defp add_issue_to_state({module_contains_import?, issues}, issue) do
    {module_contains_import?, [issue | issues]}
  end

  defp find_issue(fun_name, arguments, meta, issue_meta) do
    params = IssueMeta.params(issue_meta)
    ignored_functions = Params.get(params, :ignore, __MODULE__)
    allowed_metadata = Params.get(params, :allowed_metadata, __MODULE__)

    unless Enum.member?(ignored_functions, fun_name) do
      issue_for_call(fun_name, arguments, meta, issue_meta, allowed_metadata)
    end
  end

  defp issue_for_call(:metadata, [logger_metadata], meta, issue_meta, allowed_metadata) do
    issue_for_call(logger_metadata, meta, issue_meta, allowed_metadata)
  end

  defp issue_for_call(:log, [_, _, logger_metadata], meta, issue_meta, allowed_metadata) do
    issue_for_call(logger_metadata, meta, issue_meta, allowed_metadata)
  end

  defp issue_for_call(:log, [_, _], _meta, _issue_meta, _allowed_metadata) do
    nil
  end

  defp issue_for_call(_fun_name, [_, logger_metadata] = _args, meta, issue_meta, allowed_metadata) do
    issue_for_call(logger_metadata, meta, issue_meta, allowed_metadata)
  end

  defp issue_for_call(_fun_name, _args, _meta, _issue_meta, _allowed_metadata) do
    nil
  end

  defp issue_for_call(logger_metadata, meta, issue_meta, allowed_metadata) do
    unless Keyword.keyword?(logger_metadata) and
             logger_metadata
             |> Keyword.keys()
             |> Enum.all?(&(&1 in allowed_metadata)) do
      issue_for(issue_meta, meta[:line])
    end
  end

  defp logger_import?([{:__aliases__, _meta, [:Logger]}]), do: true
  defp logger_import?(_), do: false

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Logger metadata will be ignored in production",
      line_no: line_no
    )
  end
end
