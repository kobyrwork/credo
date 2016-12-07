defmodule Credo.Check.Readability.SpaceAroundOperatorsTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.SpaceAroundOperators

  @without_spaces """
defmodule Credo.Sample1 do
  defmodule InlineModule do
    @min -1
    @max +1

    def foobar do
      1+2
    end
  end
end
"""
  @without_spaces2 """
defmodule OtherModule3 do
  defmacro foo do
    3+4
  end

  defp bar do
    6*7
  end
end
"""
  @with_spaces """
defmodule Credo.Sample2 do
  defmodule InlineModule do
    def foo do
      <<_, unquoted::binary-size(size), _>> = quoted
      <<data::size(len)-binary, _::binary>>
      <<102::integer-native, rest::binary>>
      <<102::native-integer, rest::binary>>
      <<102::unsigned-big-integer, rest::binary>>
      <<102::unsigned-big-integer-size(8), rest::binary>>
      <<102::unsigned-big-integer-8, rest::binary>>
      <<102::8-integer-big-unsigned, rest::binary>>
      <<102, rest::binary>>
      << valsize :: 32-unsigned, rest::binary >>
    end

    def error(err_no) do
      case err_no do
        -1 -> :unknown_error
        +2 -> :known_error
        _  -> @error_map[err_no] || err_no
      end
    end

    def parse_response(<< _correlation_id :: 32-signed, error_code :: 16-signed, generation_id :: 32-signed,
                         protocol_len :: 16-signed, _protocol :: size(protocol_len)-binary,
                         leader_len :: 16-signed, leader :: size(leader_len)-binary,
                         member_id_len :: 16-signed, member_id :: size(member_id_len)-binary,
                         members_size :: 32-signed, rest :: binary >>) do
      members = parse_members(members_size, rest, [])
      %Response{error_code: KafkaEx.Protocol.error(error_code), generation_id: generation_id,
                leader_id: leader, member_id: member_id, members: members}
    end

    defp int(<< value :: size(valsize)-binary >>, x) do
      case x |> Integer.parse do
        :error -> -1
        {a, _} -> a
      end
    end

    def bar do
      c = n * -1
      c = n + -1
      c = n / -1
      c = n - -1

      [(3 * 4) + (2 / 2) - (-1 * 4) / 1 - 4]
      [(3 * 4) + (2 / 2) - (-1 * 4) / 1 - 4]
      [(3 * 4) + (2 / 2) - (-1 * 4) / 1 - 4]
      |> my_func(&Some.Deep.Module.is_something/1)
    end
  end
end
"""
  @with_spaces2 """
defmodule OtherModule3 do
  defmacro foo do
    1 && 2
  end

  defp bar do
    :ok
  end
end
"""
  @with_spaces3 """
defmodule OtherModule3 do
  defmacro foo do
    case foo do
      {line_no, line} -> nil
      {line_no, line} ->
        nil
    end
  end
end
"""
  @with_spaces4 """
defmodule OtherModule3 do
  @min -1
  @max 2 + 1
  @base_priority_map  %{low: -10, normal: 1, higher: +20}

  def foo(prio) when prio in -999..-1 do
  end

  for prio < -999..0 do
    # something
  end
end
"""
  @with_and_without_spaces """
defmodule OtherModule3 do
  defmacro foo do
    3+4
  end

  defp bar do
    6 *7
  end
end
"""
  @with_and_without_spaces2 """
defmodule OtherModule3 do
  defmacro foo do
    3+4
  end

  defp bar do
    [3 /4]
    |> my_func(&Some.Deep.Module.is_something/1)
  end
end
"""

  #
  # cases NOT raising issues
  #

  test "it should not report issues if spaces are used everywhere" do
    [
      @with_spaces, @with_spaces2, @with_spaces3, @with_spaces4
    ]
    |> to_source_files()
    |> refute_issues(@described_check)
  end

  test "it should not report issues if spaces are omitted everywhere" do
    [
      @without_spaces, @without_spaces2
    ]
    |> to_source_files()
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report an issue for mixed styles /1" do
    [
      @without_spaces, @with_spaces, @with_spaces2
    ]
    |> to_source_files()
    |> assert_issue(@described_check)
  end

  test "it should report an issue for mixed styles /2" do
    [
      @without_spaces, @with_spaces2, @with_spaces2
    ]
    |> to_source_files()
    |> assert_issue(@described_check)
  end

  test "it should report the correct result 4" do
    [
      @with_and_without_spaces
    ]
    |> to_source_files()
    |> assert_issue(@described_check)
  end

end
