defmodule CMS.NodeAntenna do
  @moduledoc """
  Represents the 'Antenna' of a CMS Node: The Synaptic Transceiver.

  Responsibilities:
  1. Modulates signal strength (Gain) for Spreading Activation.
  2. Tracks activation frequency for metabolic decay logic.
  3. Applies Physical Urgency overrides (signal_modulations).
  """

  @derive {Jason.Encoder, only: [:gain, :activation_frequency, :signal_modulations]}
  defstruct [
    :gain,                 # Float (0.0 - 2.0): Signal amplification factor
    :activation_frequency, # Float: Historical metric
    :signal_modulations    # Map: Real-time overrides
  ]

  @type t :: %__MODULE__{
    gain: float(),
    activation_frequency: float(),
    signal_modulations: map()
  }

  @doc """
  Calculates the initial antenna gain based on the node's Salience Score.
  """
  @spec calculate_gain(float()) :: float()
  def calculate_gain(salience_score) when salience_score >= 0.0 and salience_score <= 1.0 do
    salience_score * 2.0
  end

  @doc """
  Factory method for a new Antenna.
  """
  @spec new(float()) :: t()
  def new(initial_salience) do
    %__MODULE__{
      gain: calculate_gain(initial_salience),
      activation_frequency: 0.0,
      signal_modulations: %{}
    }
  end
end
