defmodule Mongoex.Server do
  def start do
    :ok = :application.start(:mongodb)
  end

  def setup(options // []) do
    :ets.new(:mongoex_server, [:set, :protected, :named_table])
    :ets.insert(:mongoex_server, {:mongoex_server, Keyword.merge(default_options, options)})
  end

  def config do
    :ets.lookup(:mongoex_server, :mongoex_server)[:mongoex_server]
  end

  def insert(table, tuple) do
    execute(fn() -> :mongo.insert(table, tuple) end)
  end

  def replace(table, selector, tuple) do
     execute(fn() -> :mongo.replace(table, selector, tuple) end)
  end

  def delete_all(table, tuple) do
    execute(fn() -> :mongo.delete(table, tuple) end)
  end

  def find(table, selector) do
    execute(fn() -> :mongo.find_one(table, selector) end)
  end

  def find_all(table, selector, options // []) do
    skip = options[:skip]
    if skip == nil do
      skip = 0
    end

    batch_size = options[:batch_size]
    if batch_size == nil do
      batch_size = 0
    end

    execute(fn() -> :mongo.find(table, selector, {}, skip, batch_size) end)
  end

  def count(table, selector) do
    execute(fn() -> :mongo.count(table,selector) end)
  end

  def execute(fun) do
    {:ok, conn} = connect
    mongo_do = function(:mongo, :do, 5)
    mongo_do.(:safe, :master, conn, config[:database], fun)
  end

  defp connect do
    :mongo.connect({config[:address], config[:port]})
  end

  defp default_options do
    [ address: 'localhost',
      port: 27017,
      database: :mongoex_test
    ]
  end
end
