defmodule Etcd.Node do
  @behaviour Access
  @directive Enumberable
  defstruct [
    dir: false,
    key: nil,
    nodes: nil,
    createdIndex: nil,
    modifiedIndex: nil,
    ttl: nil,
    expiration: nil,
  ]

  # Shamelessly stolen from elixir source.
  defimpl Collectable do
    def into(original) do
      {original, fn
        map, {:cont, {k, v}} -> :maps.put(k, v, map)
        map, :done -> map
        _, :halt -> :ok
      end}
    end
  end
  
  defimpl Enumerable do
    def reduce(map, acc, fun) do
      do_reduce(:maps.to_list(map), acc, fun)
    end

    defp do_reduce(_,     {:halt, acc}, _fun),   do: {:halted, acc}
    defp do_reduce(list,  {:suspend, acc}, fun), do: {:suspended, acc, &do_reduce(list, &1, fun)}
    defp do_reduce([],    {:cont, acc}, _fun),   do: {:done, acc}
    defp do_reduce([h|t], {:cont, acc}, fun),    do: do_reduce(t, fun.(h, acc), fun)

    def member?(map, {key, value}) do
      {:ok, match?({:ok, ^value}, :maps.find(key, map))}
    end

    def member?(_map, _other) do
      {:ok, false}
    end

    def count(map) do
      {:ok, map_size(map)}
    end
  end
  
  def from_map(map) do
    load_nodes(Enum.into(map, %Etcd.Node{}, fn({k,v})->{String.to_existing_atom(k),v} end))
  end

  defp load_nodes(%{dir: false} = node), do: node
  defp load_nodes(%{dir: true} = node), do: %{node | nodes: load_nodes(node.nodes) }
  defp load_nodes(nil), do: nil
  defp load_nodes(lst) when is_list(lst), do: Enum.map(lst, &from_map/1)
end

