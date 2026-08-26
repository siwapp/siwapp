defmodule SiwappWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use PhoenixHTMLHelpers

  @doc """
  Generates tag for inlined form input errors.
  """
  @spec error_tag(Phoenix.HTML.Form.t(), atom, Keyword.t()) :: list
  def error_tag(form, field, attrs \\ []) do
    action = if is_map(form.source), do: Map.get(form.source, :action)

    errors =
      if action != :validate or Phoenix.Component.used_input?(form[field]) do
        Keyword.get_values(form.errors, field)
      else
        []
      end

    Enum.map(errors, fn error ->
      content_tag(
        :span,
        translate_error(error),
        Keyword.put_new(attrs, :class, "invalid-feedback")
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
