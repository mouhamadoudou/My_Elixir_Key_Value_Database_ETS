defmodule MyDatabase do
  use ExUnit.Case
  doctest MyDatabase

  test "test creat" do
    assert MyDatabase_data.create(:hello) == :ok
    assert MyDatabase_data.create(:hello, "world") == :ok
    assert MyDatabase_data.read(:hello) == [hello: "world"]
  end

  test "test update value" do
    assert MyDatabase_data.update(:hello, "hello world") == :ok
    assert MyDatabase_data.read(:hello) == [hello: "hello world"]
  end

  test "test read" do
    assert MyDatabase_data.create(:hello) == :ok
    assert MyDatabase_data.create(:hello, "world") == :ok
    assert MyDatabase_data.read(:hello) == [hello: "world"]
    assert MyDatabase_data.read(:hell) == {:error, "Table dosen't exist"}
  end

  test "test delete" do
    assert MyDatabase_data.create(:hello) == :ok
    assert MyDatabase_data.create(:hello, "world") == :ok
    assert MyDatabase_data.delete(:hello) == :ok
    assert MyDatabase_data.read(:hello) == {:error, "Table dosen't exist"}
  end

end
