defmodule StarWarsServer.Database do
  use GenServer

  ### Server API

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_all, _from, %{database: database}) do
    {:reply, database, %{database: database}}
  end

  def handle_call({:get, id}, _from, %{database: database}) do
    movie = Enum.find(database, fn movie -> movie.id == id end)
    {:reply, movie, %{database: database}}
  end

  def handle_call({:create, movie}, _from, %{database: []}) do
    movie = Map.put(movie, :id, 1)
    database = [movie]
    {:reply, movie, %{database: database}}
  end

  def handle_call({:create, movie}, _from, %{database: database}) do
    id = database |> Enum.max_by(fn movie -> movie.id end) |> Map.get(:id) |> Kernel.+(1)
    movie = Map.put(movie, :id, id)
    database = database ++ [movie]
    {:reply, movie, %{database: database}}
  end

  def handle_call({:update, id, movie}, _from, %{database: database}) do
    Map.put(movie, :id, id)
    database = database
      |> Enum.reject(fn movie -> movie.id == id end)
      |> Enum.concat([movie])
    {:reply, movie, %{database: database}}
  end

  def handle_call({:patch, id, movie}, _from, %{database: database}) do
    existing_movie = Enum.find(database, fn movie -> movie.id == id end)
    movie = Map.merge(existing_movie, movie)
    database = database
      |> Enum.reject(fn movie -> movie.id == id end)
      |> Enum.concat([movie])
    {:reply, movie, %{database: database}}
  end

  def handle_call({:delete, id}, _from, %{database: database}) do
    movie = Enum.find(database, fn movie -> movie.id == id end)
    database = database
      |> Enum.reject(fn movie -> movie.id == id end)
    {:reply, movie, %{database: database}}
  end

  ### Client API

  @spec start_link() :: GenServer.on_start()
  def start_link do
    GenServer.start_link(__MODULE__, %{database: []}, name: __MODULE__)
  end

  @spec get_all() :: [map()]
  def get_all do
    GenServer.call(__MODULE__, :get_all)
  end

  @spec get(integer()) :: map()
  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  @spec create(map()) :: map()
  def create(movie) do
    GenServer.call(__MODULE__, {:create, movie})
  end

  @spec update(integer(), map()) :: map()
  def update(id, movie) do
    GenServer.call(__MODULE__, {:update, id, movie})
  end

  @spec delete(integer()) :: map()
  def delete(id) do
    GenServer.call(__MODULE__, {:delete, id})
  end

  @spec patch(integer(), map()) :: map()
  def patch(id, movie) do
    GenServer.call(__MODULE__, {:patch, id, movie})
  end

  @spec import(String.t()) :: :ok
  def import(movies_path) do
    File.read!(movies_path)
    |> Jason.decode!()
    |> Enum.map(fn movie -> transform_keys(movie) end)
    |> Enum.each(fn movie -> create(movie) end)
  end

  defp transform_keys(map) do
    map
    |> Enum.map(&trim_string/1)
    |> Enum.into(%{})
  end

  defp trim_string({k, v}) when is_binary(v), do: {k |> String.trim() |> String.to_atom(), v |> String.trim()}
  defp trim_string({k, v}), do: {k |> String.trim() |> String.to_atom(), v}
end
