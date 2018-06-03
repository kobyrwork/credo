defmodule Credo.Code.TokenTest do
  use Credo.TestHelper

  alias Credo.Code.Token

  @heredoc_interpolations_source """
  def fun() do
    a = \"\"\"
    MyModule.\#{fun(Module.value() + 1)}.SubModule.\#{name}"
    \"\"\"
  end
  """
  @heredoc_interpolations_position {1, 5, 1, 60}

  @multiple_interpolations_source ~S[a = "MyModule.#{fun(Module.value() + 1)}.SubModule.#{name}"]
  @multiple_interpolations_position {1, 5, 1, 60}

  @single_interpolations_bin_string_source ~S[a = "MyModule.SubModule.#{name}"]
  @single_interpolations_bin_string_position {1, 5, 1, 33}

  @no_interpolations_source ~S[134 + 145]
  @no_interpolations_position {1, 7, 1, 10}

  # Elixir >= 1.6.0
  if Version.match?(System.version(), ">= 1.6.0-rc") do
    @single_interpolations_list_string_source ~S[a = 'MyModule.SubModule.#{name}']
    @single_interpolations_list_string_position {1, 5, 1, 33}

    @tag :token_position
    test "should give correct token position" do
      source = @no_interpolations_source
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:int, {1, 1, 134}, '134'},
        {:dual_op, {1, 5, nil}, :+},
        {:int, {1, 7, 145}, '145'}
      ]

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @no_interpolations_position == position
    end

    @tag :token_position
    test "should give correct token position with a single interpolation" do
      source = @single_interpolations_bin_string_source
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:identifier, {1, 1, nil}, :a},
        {:match_op, {1, 3, nil}, :=},
        {:bin_string, {1, 5, nil},
         [
           "MyModule.SubModule.",
           {{1, 25, 1}, [{:identifier, {1, 27, nil}, :name}]}
         ]}
      ]

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @single_interpolations_bin_string_position == position
    end

    @tag :token_position
    test "should give correct token position with a single interpolation with list string" do
      source = @single_interpolations_list_string_source
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:identifier, {1, 1, nil}, :a},
        {:match_op, {1, 3, nil}, :=},
        {:list_string, {1, 5, nil},
         [
           "MyModule.SubModule.",
           {{1, 25, 1}, [{:identifier, {1, 27, nil}, :name}]}
         ]}
      ]

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @single_interpolations_list_string_position == position
    end

    @tag :token_position
    test "should give correct token position with multiple interpolations" do
      source = @multiple_interpolations_source
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:identifier, {1, 1, nil}, :a},
        {:match_op, {1, 3, nil}, :=},
        {:bin_string, {1, 5, nil},
         [
           "MyModule.",
           {{1, 15, 1},
            [
              {:paren_identifier, {1, 17, nil}, :fun},
              {:"(", {1, 20, nil}},
              {:alias, {1, 21, nil}, :Module},
              {:., {1, 27, nil}},
              {:paren_identifier, {1, 28, nil}, :value},
              {:"(", {1, 33, nil}},
              {:")", {1, 34, nil}},
              {:dual_op, {1, 36, nil}, :+},
              {:int, {1, 38, 1}, '1'},
              {:")", {1, 39, nil}}
            ]},
           ".SubModule.",
           {{1, 52, 1}, [{:identifier, {1, 54, nil}, :name}]}
         ]}
      ]

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @multiple_interpolations_position == position
    end

    @tag :to_be_implemented
    @tag :token_position
    test "should give correct token position with multiple interpolations in heredoc" do
      source = @heredoc_interpolations_source
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:identifier, {1, 1, nil}, :def},
        {:paren_identifier, {1, 5, nil}, :fun},
        {:"(", {1, 8, nil}},
        {:")", {1, 9, nil}},
        {:do, {1, 11, nil}},
        {:eol, {1, 13, 1}},
        {:identifier, {2, 3, nil}, :a},
        {:match_op, {2, 5, nil}, :=},
        {:bin_heredoc, {2, 7, nil},
         [
           "MyModule.",
           {{3, 10, 3},
            [
              {:paren_identifier, {3, 12, nil}, :fun},
              {:"(", {3, 15, nil}},
              {:alias, {3, 16, nil}, :Module},
              {:., {3, 22, nil}},
              {:paren_identifier, {3, 23, nil}, :value},
              {:"(", {3, 28, nil}},
              {:")", {3, 29, nil}},
              {:dual_op, {3, 31, nil}, :+},
              {:int, {3, 33, 1}, '1'},
              {:")", {3, 34, nil}}
            ]},
           ".SubModule.",
           {{3, 47, 3}, [{:identifier, {3, 49, nil}, :name}]},
           "\"\n"
         ]},
        {:eol, {4, 1, 1}},
        {:end, {5, 1, nil}},
        {:eol, {5, 4, 1}}
      ]

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @heredoc_interpolations_position == position
    end

    test "should give correct token position for map" do
      source = ~S(%{"some-atom-with-quotes": "#{filename} world"})
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:%{}, {1, 1, nil}},
        {:"{", {1, 2, nil}},
        {:kw_identifier_unsafe, {1, 3, nil}, ["some-atom-with-quotes"]},
        {:bin_string, {1, 28, nil},
         [{{1, 29, 1}, [{:identifier, {1, 31, nil}, :filename}]}, " world"]},
        {:"}", {1, 47, nil}}
      ]

      assert expected == tokens

      position = expected |> Enum.take(4) |> List.last() |> Token.position()

      assert {1, 28, 1, 47} == position
    end

    test "should give correct token position for map /2" do
      source = ~S(%{some_atom_with_quotes: "#{filename} world"})
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:%{}, {1, 1, nil}},
        {:"{", {1, 2, nil}},
        {:kw_identifier, {1, 3, nil}, :some_atom_with_quotes},
        {:bin_string, {1, 26, nil},
         [{{1, 27, 1}, [{:identifier, {1, 29, nil}, :filename}]}, " world"]},
        {:"}", {1, 45, nil}}
      ]

      assert expected == tokens

      position = expected |> Enum.take(4) |> List.last() |> Token.position()

      assert {1, 26, 1, 45} == position
    end
  end

  # Elixir <= 1.5.x
  if Version.match?(System.version(), "< 1.6.0-rc") do
    @tag :token_position
    test "token position" do
      source = @no_interpolations_source
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:number, {1, 1, 4}, 134},
        {:dual_op, {1, 5, 6}, :+},
        {:number, {1, 7, 10}, 145}
      ]

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @no_interpolations_position == position
    end

    @tag :token_position
    test "should give correct token position with a single interpolation" do
      source = @single_interpolations_bin_string_source
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:identifier, {1, 1, 2}, :a},
        {:match_op, {1, 3, 4}, :=},
        {:bin_string, {1, 5, 33},
         [
           "MyModule.SubModule.",
           {{1, 25, 32}, [{:identifier, {1, 27, 31}, :name}]}
         ]}
      ]

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @single_interpolations_bin_string_position == position
    end

    @tag :token_position
    test "should give correct token position with multiple interpolations" do
      source = @multiple_interpolations_source
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:identifier, {1, 1, 2}, :a},
        {:match_op, {1, 3, 4}, :=},
        {:bin_string, {1, 5, 60},
         [
           "MyModule.",
           {{1, 15, 41},
            [
              {:paren_identifier, {1, 17, 20}, :fun},
              {:"(", {1, 20, 21}},
              {:aliases, {1, 21, 27}, [:Module]},
              {:., {1, 27, 28}},
              {:paren_identifier, {1, 28, 33}, :value},
              {:"(", {1, 33, 34}},
              {:")", {1, 34, 35}},
              {:dual_op, {1, 36, 37}, :+},
              {:number, {1, 38, 39}, 1},
              {:")", {1, 39, 40}}
            ]},
           ".SubModule.",
           {{1, 52, 59}, [{:identifier, {1, 54, 58}, :name}]}
         ]}
      ]

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @multiple_interpolations_position == position
    end

    @tag :to_be_implemented
    @tag :token_position
    test "should give correct token position with multiple interpolations in heredoc" do
      source = @heredoc_interpolations_source
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:identifier, {1, 1, 4}, :def},
        {:paren_identifier, {1, 5, 8}, :fun},
        {:"(", {1, 8, 9}},
        {:")", {1, 9, 10}},
        {:do, {1, 11, 13}},
        {:eol, {1, 13, 14}},
        {:identifier, {2, 3, 4}, :a},
        {:match_op, {2, 5, 6}, :=},
        {:bin_string, {2, 7, 1},
         [
           "MyModule.",
           {{3, 10, 36},
            [
              {:paren_identifier, {3, 12, 15}, :fun},
              {:"(", {3, 15, 16}},
              {:aliases, {3, 16, 22}, [:Module]},
              {:., {3, 22, 23}},
              {:paren_identifier, {3, 23, 28}, :value},
              {:"(", {3, 28, 29}},
              {:")", {3, 29, 30}},
              {:dual_op, {3, 31, 32}, :+},
              {:number, {3, 33, 34}, 1},
              {:")", {3, 34, 35}}
            ]},
           ".SubModule.",
           {{3, 47, 54}, [{:identifier, {3, 49, 53}, :name}]},
           "\"\n"
         ]},
        {:eol, {4, 1, 2}},
        {:end, {5, 1, 4}},
        {:eol, {5, 4, 5}}
      ]

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @heredoc_interpolations_position == position
    end
  end
end
