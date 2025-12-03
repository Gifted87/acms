defmodule CMS.DecayManager do
  use GenServer
  require Logger

  @moduledoc """
  Orchestrates the Active Forgetting and Differential Decay processes.

  CRITICAL UPDATE: Eviction logic is enhanced to use both metabolic state and
  link strength for a more bio-mimetic 'active forgetting' (Gap 15).
  """

  # Configuration
  @decay_cycle_interval :timer.hours(1)
  @eviction_check_interval :timer.minutes(15)
  @low_energy_threshold :hibernating
  @min_eviction_weight 0.1 # New: The maximum average link weight for a node to be evicted

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Process.send_after(self(), :trigger_decay_cycle, @decay_cycle_interval)
    Process.send_after(self(), :trigger_eviction_check, @eviction_check_interval)
    {:ok, %{}}
  end

  # Callbacks

  @impl true
  def handle_info(:trigger_decay_cycle, state) do
    Logger.info("DecayManager: Starting global decay cycle.")

    CMS.NodeSupervisor.get_all_active_node_pids()
    |> Enum.each(fn pid ->
      GenServer.cast(pid, :perform_differential_decay)
    end)

    Process.send_after(self(), :trigger_decay_cycle, @decay_cycle_interval)
    {:noreply, state}
  end

  @impl true
  # --- LOGIC UPDATE: Refactored eviction check to use dual criteria ---
  def handle_info(:trigger_eviction_check, state) do
    Logger.debug("DecayManager: Auditing nodes for critical low energy and low link strength.")

    count_evicted =
      CMS.NodeSupervisor.get_all_active_node_pids()
      |> Enum.count(fn pid ->
        try do
          # 1. Use the new GenServer call to get dual criteria
          # Returns: {:ok, {internal_state, total_link_weight}}
          {:ok, {internal_state, total_link_weight}} = GenServer.call(pid, :get_decay_criteria, 1000)

          # 2. Check both criteria for eviction
          if internal_state == @low_energy_threshold and total_link_weight < @min_eviction_weight do
             Logger.info("Evicting Node due to internal_state: #{internal_state} and total_link_weight: #{total_link_weight}.")
             # Force stop
             GenServer.stop(pid, :normal)
             true
          else
             false
          end
        catch
          :exit, _ -> false # Node died during check
          _, _ -> false # GenServer call failed/timed out
        end
      end)

    if count_evicted > 0 do
      Logger.info("DecayManager: Evicted #{count_evicted} hibernating, low-strength nodes.")
    end

    Process.send_after(self(), :trigger_eviction_check, @eviction_check_interval)
    {:noreply, state}
  end
end
