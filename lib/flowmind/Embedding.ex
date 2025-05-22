defmodule Flowmind.Embedding do
  import Ecto.Query, warn: false
  import Pgvector.Ecto.Query
  import Ecto.Changeset
  alias Flowmind.Repo
  alias Flowmind.Embed.Document
  alias Flowmind.EmbeddingGenserver

  # Ingest:
  # # search_document
  # # clustering
  # # classification
  #
  # Retrieve:
  # # search_query

  def chunk_input(document, b \\ 5) do
    data = File.stream!(document) |> Enum.join()

    opts = [
      chunk_size: 300,
      chunk_overlap: 20,
      format: :plaintext,
      strategy: TextChunker.Strategies.RecursiveChunk
    ]
    
    TextChunker.split(data, opts)
    |> Enum.chunk_every(b)
    |> Enum.each(fn batch ->
      text = batch |> Enum.map(& &1.text |> String.replace(["\n", "*"], ""))
        IO.inspect(text)
        ingest(text, "search_document")
      end)
  end

  def ingest(input, task) when is_binary(input), do: ingest([input], task)

  def ingest(input, task) do
    tenant = Flowmind.TenantContext.get_tenant()

    input_mask =
      # input |> Stream.map(fn i -> "#{task}: #{i}" end) |> Enum.to_list()
      input |> Stream.map(fn i -> i end) |> Enum.to_list()

    embedding = EmbeddingGenserver.embed(input_mask)

    Stream.zip(Stream.map(input, & &1), Stream.map(embedding, & &1))
    |> Stream.map(fn {text, embedding} ->
      Repo.insert(%Document{text: text, embedding: embedding}, prefix: tenant)
    end)
    |> Stream.run()
  end

  def retrieve(text, task \\ "search_query", k \\ 3) do
    tenant = Flowmind.TenantContext.get_tenant()
    IO.inspect("#{task}: #{text}")
    [embedding] = EmbeddingGenserver.embed("#{task}: #{text}")
    [embedding] = EmbeddingGenserver.embed(text)
    
    Repo.all(
      from d in Document,
        prefix: ^tenant,
        select: d.text,
        order_by: cosine_distance(d.embedding, ^embedding),
        limit: ^k
    )
  end
end
