defmodule SiwappWeb.MetaAttributesComponentTest do
  use SiwappWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SiwappWeb.MetaAttributesComponent

  test "disables LiveView unused-field tracking for meta attributes" do
    form =
      Phoenix.Component.to_form(
        %{"meta_attributes" => %{"country" => "Germany"}},
        as: :invoice
      )

    html =
      render_component(MetaAttributesComponent,
        id: "meta-attributes",
        f: form,
        field: :meta_attributes
      )

    assert html =~ "country"
    assert html =~ "Germany"
    assert html =~ "phx-no-unused-field"
  end
end
