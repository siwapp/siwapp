defmodule SiwappWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  import Phoenix.HTML.Form
  use PhoenixHTMLHelpers


  @doc """
  Generates tag for inlined form input errors.
  """
  @spec error_tag(Phoenix.HTML.Form.t(), atom, Keyword.t()) :: list
  def error_tag(form, field, attrs \\ []) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(
        :span,
        translate_error(error),
        Keyword.merge(
          [class: "invalid-feedback", phx_feedback_for: input_name(form, field)],
          attrs
        )
      )
    end)
  end

  @doc """
  Translates an error message using gettext.
  """
  @spec translate_error({binary, keyword}) :: binary
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(SiwappWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(SiwappWeb.Gettext, "errors", msg, opts)
    end
  end
end
