defmodule SiwappWeb.GraphicHelpers do
  @moduledoc false
  alias Contex.Dataset
  alias Contex.LinePlot
  alias Contex.Plot

  @doc """
  Returns a SVG graphic of a line plot (500x200 size) with the given 'data'.

  'data' must be a list of tuples with size of 2.
  """
  @spec line_plot([{any(), any()}], keyword()) :: {:safe, [...]}
  def line_plot(data, options \\ []) do
    default = [x_formatter: nil, y_formatter: nil]
    options = Keyword.merge(default, options)

    plot_options = [
      stroke_width: 1,
      smoothed: false,
      custom_x_formatter: options[:x_formatter],
      custom_y_formatter: options[:y_formatter]
    ]

    margins = %{left: 35, right: 15, top: 10, bottom: 20}

    data
    |> Dataset.new()
    |> Plot.new(LinePlot, 500, 110, plot_options)
    |> Map.put(:margins, margins)
    |> Plot.to_svg()
  end
end
