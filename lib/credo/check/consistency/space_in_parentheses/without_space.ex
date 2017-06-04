defmodule Credo.Check.Consistency.SpaceInParentheses.WithoutSpace do
  use Credo.Check.CodePattern

  alias Credo.Check.CodeHelper
  alias Credo.Code

  @regex ~r/[^\?]([\{\[\(]\S|\S[\)\]\}])/

  def property_value, do: :without_space

  def property_value_for(source_file, _params) do
    source_file
    |> CodeHelper.clean_charlists_strings_sigils_and_comments
    |> Code.to_lines
    |> Enum.map(&property_value_for_line/1)
  end

  defp property_value_for_line({line_no, line}) do
    results = Regex.run(@regex, line)

    if results do
      trigger = Enum.at(results, 1)

      PropertyValue.for(property_value(), line_no: line_no, trigger: trigger)
    end
  end
end
