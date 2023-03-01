defmodule StarWarsServer.EtsDatabse do
  use GenServer

  ### Server API
  def init(state) do
    :ets.new(:database, [:named_table, :public, :set])
    {:ok, state}
  end

  def handle_call(:get_all, _from, state) do
    movie_lsit = :ets.tab2list(:database)
    |> Enum.map(fn {id, movie} -> Map.put(movie, :id, id) end)
    {:reply, movie_lsit, state}
  end

  def handle_call({:get, id}, _from, state) do
    [{id, movie}] = :ets.lookup(:database, id)
    movie = Map.put(movie, :id, id)
    {:reply, movie, state}
  end

  def handle_call({:create, movie}, _from, state) do
    id = if :ets.info(:database, :size) == 0 do
      1
    else
      :ets.tab2list(:database) |> Enum.max_by(fn {id, _movie} -> id end) |> elem(0) |> Kernel.+(1)
    end
    :ets.insert(:database, {id, movie})
    {:reply, Map.put(movie, :id, id), state}
  end

  def handle_call({:update, id, movie}, _from, state) do
    :ets.insert(:database, {id, movie})
    {:reply, Map.put(movie, :id, id), state}
  end

  def handle_call({:patch, id, movie}, _from, state) do
    [{id, existing_movie}] = :ets.lookup(:database, id)
    movie = Map.merge(existing_movie, movie)
    :ets.insert(:database, {id, movie})
    {:reply, Map.put(movie, :id, id), state}
  end

  def handle_call({:delete, id}, _from, state) do
    [{_id, movie}] = :ets.lookup(:database, id)
    :ets.delete(:database, id)
    {:reply, Map.put(movie, :id, id), state}
  end

  ### Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def get_all do
    GenServer.call(__MODULE__, :get_all)
  end

  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  def create(movie) do
    GenServer.call(__MODULE__, {:create, movie})
  end

  def update(id, movie) do
    GenServer.call(__MODULE__, {:update, id, movie})
  end

  def patch(id, movie) do
    GenServer.call(__MODULE__, {:patch, id, movie})
  end

  def delete(id) do
    GenServer.call(__MODULE__, {:delete, id})
  end

  def import(movie_path) do
    File.read!(movie_path)
    |> Jason.decode!()
    |> Enum.map(fn movie -> transform_keys(movie) end)
    |> Enum.each(fn movie -> create(movie) end)
  end

  defp transform_keys(map) do
    map
    |> Enum.map(&trim_string/1)
    |> Enum.into(%{})
  end

  defp trim_string({k, v}) when is_binary(v),
    do: {k |> String.trim() |> String.to_atom(), v |> String.trim()}

  defp trim_string({k, v}), do: {k |> String.trim() |> String.to_atom(), v}
end
