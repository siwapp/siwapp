defmodule SiwappWeb.Component.Sortener do
  @moduledoc """
  The sortener button component.
  """

  use Phoenix.Component
  
  defstruct field: nil, order: nil

  @spec sortener_button(map) :: Phoenix.LiveView.Rendered.t()
  def sortener_button(assigns) do
    ~H"""
      <%= if @sort_map.field == @current_field and @sort_map.order == "asc" do %>
      <span class="pointer" phx-click="reorder" phx-value-field={@current_field} phx-value-order="desc">
        <svg width="16px" height="16px" viewBox="0 0 24 24" fill="none" style="vertical-align: middle;" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 6V18M12 6L7 11M12 6L17 11" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </span>
      <% end %>
      <%= if @sort_map.field == @current_field and @sort_map.order == "desc" do %>
      <span class="pointer" phx-click="reorder" phx-value-field={@current_field}>
        <svg width="16px" height="16px" viewBox="0 0 24 24" fill="none" style="vertical-align: middle;" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 6V18M12 18L7 13M12 18L17 13" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </span>
      <% end %>
      <%= if @sort_map.field != @current_field do %>
      <span class="pointer" phx-click="reorder" phx-value-field={@current_field} phx-value-order="asc">
        <svg width="16px" height="16px" viewBox="0 0 24 24" fill="none" style="transform: rotate(90deg);vertical-align: middle;" xmlns="http://www.w3.org/2000/svg">
          <path d="M19.75 16C19.75 16.41 19.41 16.75 19 16.75H6.81L8.03 17.97C8.32 18.26 8.32 18.74 8.03 19.03C7.88 19.18 7.69 19.25 7.5 19.25C7.31 19.25 7.12 19.18 6.97 19.03L4.47 16.53C4.4 16.46 4.35 16.38 4.31 16.29C4.23 16.11 4.23 15.9 4.31 15.72C4.35 15.63 4.4 15.55 4.47 15.48L6.97 12.98C7.26 12.69 7.74 12.69 8.03 12.98C8.32 13.27 8.32 13.75 8.03 14.04L6.81 15.26H19C19.41 15.26 19.75 15.6 19.75 16.01V16ZM5 8.75001H17.19L15.97 9.97001C15.68 10.26 15.68 10.74 15.97 11.03C16.12 11.18 16.31 11.25 16.5 11.25C16.69 11.25 16.88 11.18 17.03 11.03L19.53 8.53001C19.6 8.46001 19.65 8.38001 19.69 8.29001C19.77 8.11001 19.77 7.90001 19.69 7.72001C19.65 7.63001 19.6 7.55001 19.53 7.48001L17.03 4.98001C16.74 4.69001 16.26 4.69001 15.97 4.98001C15.68 5.27001 15.68 5.75001 15.97 6.04001L17.19 7.26001H5C4.59 7.26001 4.25 7.60001 4.25 8.01001C4.25 8.42001 4.59 8.76001 5 8.76001V8.75001Z" fill="#000000"/>
        </svg>
      </span>
      <% end %>
    """
  end
end