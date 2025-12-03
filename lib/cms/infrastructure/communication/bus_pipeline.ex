defmodule CMS.BusPipeline do
  use Broadway
  require Logger

  @moduledoc """
  The Back-Pressure Pipeline for the Cognitive Bus.

  Implements Gap 8.
  Consumes events from CMS.QueryRouter and broadcasts them to
  Semantic Regions via Phoenix.PubSub.
  """

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {CMS.QueryRouter, []},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 50, # Max 50 concurrent broadcasts allowed
          max_demand: 10   # Prefetch 10 items per processor
        ]
      ],
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 50
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processor, message, _context) do
    {query_context, target_regions} = message.data

    # FIX: Utilize the variables for observability instead of ignoring them
    Logger.metadata(
      query_id: query_context[:query_id],
      target_region_count: length(target_regions)
    )

    Broadway.Message.put_batcher(message, :default)
  end

  @impl true
  def handle_batch(:default, messages, _batch_info, _context) do
    # Execute the broadcasts
    Enum.each(messages, fn message ->
      {query_context, target_regions} = message.data
      do_broadcast(query_context, target_regions)
    end)

    # Clean up metadata
    Logger.metadata(query_id: nil, target_region_count: nil)

    messages
  end

  defp do_broadcast(query_context, target_regions) do
    # Broadcast to each target semantic region
    Enum.each(target_regions, fn region_id ->
      topic = "region:#{region_id}"

      # The payload is the query context
      # NodeActors subscribed to this topic will wake up
      Phoenix.PubSub.broadcast(
        CMS.PubSub,
        topic,
        {:query, query_context}
      )
    end)
  end
end
