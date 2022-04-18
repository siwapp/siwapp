defmodule SiwappWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use SiwappWeb, :controller
      use SiwappWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  @spec controller :: tuple
  def controller do
    quote do
      use Phoenix.Controller, namespace: SiwappWeb

      import Plug.Conn
      import SiwappWeb.Gettext
      alias SiwappWeb.Router.Helpers, as: Routes
    end
  end

  @spec view :: tuple
  def view do
    quote do
      use Phoenix.View,
        root: "lib/siwapp_web/templates",
        namespace: SiwappWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())

      @spec template_not_found(binary, map) :: binary
      def template_not_found(template, _assigns) do
        Phoenix.Controller.status_message_from_template(template)
      end
    end
  end

  @spec live_view :: tuple
  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {SiwappWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  @spec live_component :: tuple
  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  @spec router :: tuple
  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  @spec channel :: tuple
  def channel do
    quote do
      use Phoenix.Channel
      import SiwappWeb.Gettext
    end
  end

  @spec view_helpers :: tuple
  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers
      import SiwappWeb.LiveHelpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import SiwappWeb.ErrorHelpers
      import SiwappWeb.Gettext
      alias SiwappWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
