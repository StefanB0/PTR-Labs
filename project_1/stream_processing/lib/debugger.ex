defmodule Debugger do
  def d_print(message, checkmark \\ true) do
    if check_debug() && checkmark do
      IO.puts(message)
    end
  end

  def d_inspect(object, checkmark \\ true) do
    if check_debug() && checkmark do
      IO.inspect(object)
    end
  end

  def check_debug() do
    Application.get_env(:stream_processing, :debug)
  end
end
