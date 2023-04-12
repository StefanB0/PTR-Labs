defmodule MessageAnalyst do
  use GenServer
  require Logger

  # Server API

  def init(_args) do
    state = %{tags: %{"Hello-world" => 0}, users: %{0 => %{name: "NaN", engagement: 0, posts: 0}}}
    spawn_link(&run_timer/0)
    Logger.info("MessageAnalyst worker started")
    {:ok, state}
  end

  ## Server callbacks

  def handle_cast({:tweet, message}, state) do
    state = %{
      state | tags:
        message.hashtags
        |> Enum.map(fn item -> item.text end)
        |> Enum.frequencies()
        |> Map.merge(state.tags, fn _key, value1, value2 ->
          value1 + value2
        end)
    }

    {:noreply, state}
  end

  def handle_cast(:print, state) do
    state.tags
    |> Enum.max_by(fn {_k, v} -> v end)
    |> (&"Most popular hashtag is: ##{elem(&1, 0)}: #{elem(&1, 1)}").()
    |> (&IO.ANSI.format([:green, &1])).()
    |> then(& !Debugger.check_debug() && IO.puts(&1))

    most_engaged_user = state.users |> Enum.max_by(fn {_k, v} -> v.engagement end) |> elem(1)
    "Most engaged user is: #{most_engaged_user.name} with #{most_engaged_user.engagement} engagement and #{most_engaged_user.posts} posts"
    |> then(&IO.ANSI.format([:green, &1]))
    |> then(& !Debugger.check_debug() && IO.puts(&1))
    {:noreply, state}
  end

  def handle_cast({:user_engagemet, tweet}, state) do
    user = state.users[tweet.user_id] || %{name: tweet.user, engagement: 0, posts: 0}
    new_engagement = (user.engagement * user.posts + tweet.engagement_ratio) / (user.posts + 1)
    user = %{user | engagement: new_engagement, posts: user.posts + 1}
    # user_base = %{state.users | tweet.user_id => user}
    user_base = Map.put(state.users, tweet.user_id, user)
    state = %{state | users: user_base}

    Debugger.d_print("User #{tweet.user_id} has #{user.posts} posts and #{user.engagement} engagement", :user_engagement)
    {:noreply, state}
  end

  # Client API

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def add_user_engagement(tweet) do
    GenServer.cast(__MODULE__, {:user_engagemet, tweet})
  end

  # Logic

  def run_timer() do
    Process.sleep(5 * 1000)
    GenServer.cast(MessageAnalyst, :print)
    run_timer()
  end
end
