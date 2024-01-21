defmodule MyDatabase_data do
  use GenServer

  #CLient

  def start_link(_) do
    GenServer.start_link(__MODULE__, :data, name: :data_base)
  end

  def read (key) do
    GenServer.call(:data_base, {:read, key})
  end


  def load_to_database(json_file) do
    GenServer.call(:data_base, {:load_to_db, json_file})
  end

  def search(criteria) do
    GenServer.call(:data_base, {:search, criteria})
  end

  def create(key, value) do
    GenServer.cast(:data_base, {:creat, key, value})
  end

  def create(key) do
    GenServer.cast(:data_base, {:creat, key, []})
  end

  def update(key, new_value) do
    GenServer.cast(:data_base, {:update, key, new_value})
  end

  def delete(key) do
    GenServer.cast(:data_base, {:delete, key})
  end

  defp lookup(:data_base, key) do
    case :ets.lookup(:data_base, key) do
      [_] -> :ok
      [] -> :error
    end
  end

  #Server

  def init(_) do
    :ets.new(:data_base, [:named_table, :set])
    {:ok, :data_base}
  end

  defp load_db(:data_base, orders, new_orders) do
    [order | list] = orders

    :ets.insert(:data_base, {Map.get(order, "vclock"), order})

    case list do
      [] -> {:ok, new_orders}
      _ -> load_db(:data_base, list, new_orders)
    end
  end

  defp search_criteria_filter_m(key, data, criteria) when is_map(data) do
    test = Enum.map(data, fn {key, value} ->
      case search_criteria_filter(key, value, criteria) do
        true -> true
        false -> false
      end
    end)
    Enum.member?(test, true)
  end

  defp search_criteria_filter(key, value, criteria) when is_tuple(value) or is_list(value) or is_map(value) do
    false
  end

  defp search_criteria_filter(key, value, criteria) do
    # IO.inspect(key)
    # IO.inspect(Enum.at(criteria, 0))
    result = (key == Enum.at(criteria, 0) and value == Enum.at(criteria, 1))
    # IO.inspect(result)
    result
  end

  defp search_criteria_map(orders, criteria) do
    data = elem(List.first(orders), 1)

    # IO.inspect(data)
    test = Enum.map(data, fn {key, value} ->
      case search_criteria_filter(key, value, criteria) do
        true -> true
        false -> false
      end
    end)
    Enum.member?(test, true)
  end

  defp search_criteria(:data_base, criteria, result, key) when key == :"$end_of_table" do
    {:ok, result}
  end

  defp search_criteria(:data_base, criteria, result, key) do
    case search_criteria_map(:ets.lookup(:data_base, key), criteria) do
      true ->
        result = [key | result]
        {:ok, result} = search_criteria(:data_base, criteria, result, :ets.next(:data_base, key))
      false ->
        {:ok, result} = search_criteria(:data_base, criteria, result, :ets.next(:data_base, key))
    end
  end

  def handle_call({:search, criteria}, _from, :data_base) do
    result = []
    first_key = :ets.first(:data_base)
    {:ok, result} = search_criteria(:data_base, criteria, result, first_key)
    IO.inspect(result)
    {:reply, :ok, :data_base}
  end

  def handle_call({:read, key}, _from, :data_base) do
    resp = :ets.lookup(:data_base, key)
    case lookup(:data_base, key) do
      :error -> {:reply, {:error, "Table dosen't exist"}, :data_base}
      :ok -> {:reply, resp, :data_base}
    end
  end

  def handle_call({:load_to_db, json_file}, _from, :data_base) do
    case File.read(json_file) do
      {:error, reason} -> {:reply, {:error, "File read error #{reason}"}, :data_base}
      {:ok, json_data} ->
        case Poison.decode(json_data) do
          {:ok, data} ->
            new_data = %{}
            {:ok, new_data} = load_db(:data_base, data, new_data)
            {:reply, :ok, :data_base}
          {:error, reason} -> {:reply, {:error, "File read error #{reason}"}, :data_base}
        end
    end
  end


  def handle_cast({:update, key, new_value}, :data_base) do
    :ets.insert(:data_base, {key, new_value})
    {:noreply, :data_base}
  end


  def handle_cast({:creat, key, value}, :data_base) do
    :ets.insert(:data_base, {key, value})
    {:noreply, :data_base}
  end

  def handle_cast({:delete, key}, :data_base) do
    :ets.delete(:data_base, key)
    {:noreply, :data_base}
  end
end
