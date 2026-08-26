defmodule SiwappWeb.MetaAttributesComponentTest do
  use SiwappWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SiwappWeb.LiveHelpers
  alias SiwappWeb.MetaAttributesComponent

  test "does not render LiveView unused-field markers as meta attributes" do
    form =
      Phoenix.Component.to_form(
        %{
          "meta_attributes" => %{
            "_unused_country" => "",
            "country" => "Germany"
          }
        },
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
    refute html =~ "_unused_country"
  end

  test "removes LiveView unused-field markers from submitted meta attributes" do
    params = %{
      "name" => "Invoice",
      "meta_attributes" => %{
        "_unused_country" => "",
        "country" => "Germany"
      }
    }

    assert LiveHelpers.remove_unused_meta_attributes(params) == %{
             "name" => "Invoice",
             "meta_attributes" => %{"country" => "Germany"}
           }
  end
end
