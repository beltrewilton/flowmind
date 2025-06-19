defmodule Flowmind.LLMExperiment do
  alias LangChain.Function
  alias LangChain.Message
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Utils.ChainResult
  alias LangChain.Chains.RoutingChain
  alias LangChain.Routing.PromptRoute

  def call(message) do
    # map of data we want to be passed as `context` to the function when
    # executed.
    custom_context = %{
      "user_id" => 123,
      "hairbrush" => "drawer",
      "dog" => "backyard",
      "sandwich" => "kitchen"
    }

    # a custom Elixir function made available to the LLM
    custom_fn =
      Function.new!(%{
        name: "custom",
        description: "Returns the location of the requested element or item.",
        parameters_schema: %{
          type: "object",
          properties: %{
            thing: %{
              type: "string",
              description: "The thing whose location is being requested."
            }
          },
          required: ["thing"]
        },
        function: fn %{"thing" => thing} = _arguments, context ->
          # our context is a pretend item/location location map
          {:ok, context[thing]}
        end
      })

    custom_fn_2 =
      Function.new!(%{
        name: "custom_rag",
        description: "Returns the sentence of the user input for an online bank.",
        parameters_schema: %{
          type: "object",
          properties: %{
            sentence: %{
              type: "string",
              description: "The sentence whose user is being requested."
            }
          },
          required: ["sentence"]
        },
        function: fn %{"sentence" => sentence} = _arguments, context ->
          # our context is a pretend item/location location map
          {:ok, "Your bank account is empty."}
        end
      })

    # create and run the chain
    {:ok, updated_chain} =
      LLMChain.new!(%{
        llm: ChatOpenAI.new!(),
        custom_context: custom_context,
        verbose: true
      })
      |> LLMChain.add_tools([custom_fn, custom_fn_2])
      |> LLMChain.add_message(Message.new_user!(message))
      |> LLMChain.run(mode: :while_needs_response)
  end

  def routes do
    model = %{model: "gpt-4o", stream: false}

    # input_text = "Let's create a marketing blog post about our new product 'Fuzzy Furies'"
    input_text = "Hey yo! whats up! Your name is?"

    {:ok, marketing_email_chain} =
      LLMChain.new!(%{
        llm: ChatOpenAI.new!(model),
        verbose: true
      })
      |> LLMChain.add_message(Message.new_system!("You are a marketing assistant."))
      |> LLMChain.run(mode: :while_needs_response)

    {:ok, blog_post_chain} =
      LLMChain.new!(%{
        llm: ChatOpenAI.new!(model),
        verbose: true
      })
      |> LLMChain.add_message(Message.new_system!("You are a blog post assistant."))
      |> LLMChain.run(mode: :while_needs_response)

    {:ok, fallback_chain} =
      LLMChain.new!(%{
        llm: ChatOpenAI.new!(model),
        verbose: true
      })
      |> LLMChain.add_message(Message.new_system!("You are a chitchat assistant called 'Coco'."))
      |> LLMChain.run(mode: :while_needs_response)

    routes = [
      PromptRoute.new!(%{
        name: "marketing_email",
        description: "Create a marketing focused email",
        chain: marketing_email_chain
      }),
      PromptRoute.new!(%{
        name: "blog_post",
        description: "Create a blog post that will be linked from the company's landing page",
        chain: blog_post_chain
      })
    ]

    %PromptRoute{chain: selected_route} =
      RoutingChain.new!(%{
        llm: ChatOpenAI.new!(%{model: "gpt-4o-mini", stream: false}),
        input_text: input_text,
        routes: routes,
        default_route: PromptRoute.new!(%{name: "DEFAULT", chain: fallback_chain})
      })
      |> RoutingChain.evaluate()

    selected_route
    |> LLMChain.add_message(Message.new_user!(input_text))
    |> LLMChain.run()

    # The PromptRoute for the `blog_post` should be returned as the `selected_route`.
  end

  # Flowmind.LLMExperiment.call("")
  # message = "Where is the hairbrush located?"
  # print the LLM's answer
  # IO.puts(ChainResult.to_string!(updated_chain))
  # => "The hairbrush is located in the drawer."
  #
  def embedding(input, model_id) when is_binary(input), do: embedding([input], model_id)

  def embedding(input, model_id) do
    # model_id = "sentence-transformers/all-MiniLM-L6-v2"
    {:ok, model_info} = Bumblebee.load_model({:hf, model_id}, module: Bumblebee.Text.Bert)
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_id}, type: :xlm_roberta)

    serving =
      Bumblebee.Text.text_embedding(model_info, tokenizer,
        output_attribute: :hidden_state,
        output_pool: :mean_pooling,
        embedding_processor: :l2_norm
      )

    for v <- Nx.Serving.run(serving, input), do: v[:embedding]
  end
end

# input = "The dog is barking"
# model_id = "sentence-transformers/all-MiniLM-L6-v2"
# model_id = "nomic-ai/nomic-embed-text-v2-moe"
# Flowmind.LLMExperiment.embedding(input, model_id)
