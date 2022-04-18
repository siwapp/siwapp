defmodule SiwappWeb.LiveHelpers do
  @moduledoc false
  import Phoenix.LiveView.Helpers

  @doc """
  Renders a component inside the `SiwappWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.
  """
  @spec live_modal(atom, keyword) :: Phoenix.LiveView.Component.t()
  def live_modal(component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(SiwappWeb.ModalComponent, modal_opts)
  end

  @spec type_of_period(binary, integer) :: binary
  def type_of_period(period_type, period) do
    case period_type do
      "Daily" -> singular_or_plural(period, "day")
      "Monthly" -> singular_or_plural(period, "month")
      "Yearly" -> singular_or_plural(period, "year")
    end
  end

  @spec singular_or_plural(integer, binary) :: binary
  defp singular_or_plural(period, str) do
    if period > 1 do
      str <> "s"
    else
      str
    end
  end

  @spec maybe_add(list, list) :: {list, non_neg_integer()}
  def maybe_add(current_list, []) do
    {current_list, 1}
  end

  def maybe_add(current_list, next_list) do
    {current_list ++ next_list, 0}
  end
end
