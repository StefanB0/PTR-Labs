defmodule Debugger do
  def d_print(message, option \\ :none) do
    if check_debug(option) do
      IO.puts(message)
    end
  end

  def d_inspect(object, option \\ :none) do
    if check_debug(option) do
      IO.inspect(object)
    end
  end

  def check_debug(option \\ :none) do
    Application.get_env(:stream_processing, :debug) &&
      (option == :none || option in Application.get_env(:stream_processing, :debug_options))
  end
end
