defmodule MyDatabase do
  use Application

  def start(_type, _args) do
    MyDatabase_sup.start_link([])
  end
end
