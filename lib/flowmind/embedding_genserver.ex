defmodule Flowmind.EmbeddingGenserver do
  use GenServer

  # @model_id "nomic-ai/nomic-embed-text-v2-moe"
  @model_id "sentence-transformers/all-MiniLM-L6-v2"
  # Client API
  #
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def embed(input) when is_binary(input), do: embed([input])

  def embed(input) do
    GenServer.call(__MODULE__, {:embed, input})
  end

  # Server callbacks

  @impl true
  def init(state) do
    {:ok, state, {:continue, :model_loader}}
  end

  @impl true
  def handle_continue(:model_loader, _state) do
    {:ok, model} = Bumblebee.load_model({:hf, @model_id})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, @model_id})

    IO.puts("Model [nomic-embed-text-v2-moe] loaded ⚡️")

    {:noreply, %{model: model, tokenizer: tokenizer}}
  end

  @impl true
  def handle_call({:embed, input}, _from, state) do
    serving =
      Bumblebee.Text.text_embedding(state.model, state.tokenizer,
        output_attribute: :hidden_state,
        output_pool: :mean_pooling,
        embedding_processor: :l2_norm
      )

    embedding = for v <- Nx.Serving.run(serving, input), do: v[:embedding]

    {:reply, embedding, state}
  end
end
