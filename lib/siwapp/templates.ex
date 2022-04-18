defmodule Siwapp.Templates do
  @moduledoc """
  The Templates context. It handles Templates.
  """

  import Ecto.Query, warn: false
  alias Siwapp.Invoices
  alias Siwapp.Repo
  alias Siwapp.Settings
  alias Siwapp.Templates.Template

  @doc """
  Returns the list of templates.

  ## Examples

      iex> list()
      [%Template{}, ...]

  """
  @spec list :: [Template.t()]
  def list do
    Template
    |> order_by(asc: :id)
    |> Repo.all()
  end

  @doc """
  Gets a single template. You can call it with its id as parameter, or
  by indicating that you want to get a default template, giving the
  corresponding atom (':print_default' or ':email_default')

  ## Examples

      iex> get(2)
      %Template{}

      iex> get(:print_default)
      %Template{}

      iex> get(5)
      nil
        # because that template doesn't exist

  """
  @spec get(non_neg_integer() | :print_default | :email_default) :: Template.t() | nil
  def get(id) when is_number(id), do: Repo.get(Template, id)

  def get(default_key) when is_atom(default_key),
    do: Repo.get_by(Template, %{default_key => true})

  @doc """
  Creates a template.

  ## Examples

      iex> create(%{name: "Print Default", template: "<html>..."})
      {:ok, %Template{}}

      iex> create(%{name: "Print Default"})
      {:error, %Ecto.Changeset{}}
        # because template field is required

      iex> create(%{print_default: true})
      {:error, "You cannot directly assign..."}
  """
  @spec create(map) :: {:ok, Template.t()} | {:error, any()}
  def create(attrs \\ %{})

  def create(%{print_default: _}) do
    {:error,
     "You cannot directly assign the print_default key. Use set_default(:print, template) instead."}
  end

  def create(%{email_default: _}) do
    {:error,
     "You cannot directly assign the email_default key. Use set_default(:email, template) instead."}
  end

  def create(attrs) do
    with {:ok, template} <- insert_new(attrs),
         {:yes, template} <- check_if_its_the_first(template),
         {:ok, template} <- set_default(:print, template),
         {:ok, template} <- set_default(:email, template) do
      {:ok, template}
    else
      any -> any
    end
  end

  @doc """
  Updates a template.

  ## Examples

      iex> update(template, %{name: "Print Default"})
      {:ok, %Template{}}

      iex> update(template, %{name: 8})
      {:error, %Ecto.Changeset{}}
        # because name cannot be an integer

      iex> update(template, %{email_default: true})
      {:error, "You cannot directly assign..."}
  """
  @spec update(Template.t(), map) :: {:ok, Template.t()} | {:error, any()}
  def update(_template, %{print_default: _}) do
    {:error,
     "You cannot directly assign the print_default key. Use set_default(:print, template) instead."}
  end

  def update(_template, %{email_default: _}) do
    {:error,
     "You cannot directly assign the email_default key. Use set_default(:email, template) instead."}
  end

  def update(%Template{} = template, attrs) do
    template
    |> Template.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Choose a new template for being the default one, either for printing or emails.

  You'll have to indicate of which type this template will be the default: printing
  (the parameter you need to pass is ':print') or email (':email').

  ## Examples

      iex> set_default(:print, template)
      {:ok, %Template{}}
        # That template now has the default_print attribute as true,
        and the others templates as false

      iex> set_default(:print, template)
      {:error, %Ecto.Changeset{}}
        # That template doesn't exist

  """
  @spec set_default(:print | :email, Template.t() | nil) ::
          {:ok, Template.t()} | {:error, Ecto.Changeset.t()}
  def set_default(:print, template) do
    if template.print_default do
      changeset =
        template
        |> Siwapp.Templates.change()
        |> Ecto.Changeset.add_error(
          :print_default,
          "There must be one and only one print default. To unset this one, choose another template as print default"
        )

      {:error, changeset}
    else
      change_default(:print_default, template)
    end
  end

  def set_default(:email, template) do
    if template.email_default do
      changeset =
        template
        |> Siwapp.Templates.change()
        |> Ecto.Changeset.add_error(
          :email_default,
          "There must be one and only one email default. To unset this one, choose another template as email default"
        )

      {:error, changeset}
    else
      change_default(:email_default, template)
    end
  end

  @doc """
  Deletes a template.

  ## Examples

      iex> delete(template)
      {:ok, %Template{}}

      iex> delete(template)
      {:error, %Ecto.Changeset{}}
        # because that template doesn't exist

      iex> delete(template)
      {:error, "The template you're aiming..."}
        # because that template is the default one

  """
  @spec delete(Template.t()) :: {:ok, Template.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Template{} = template) do
    if get(:print_default) == template or get(:email_default) == template do
      {:error, "The series you're aiming to delete is a default template,  \
      either for printing or emails. Change the default template first with \
      set_default/2 function."}
    else
      Repo.delete(template)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template changes.

  ## Examples

      iex> change(template)
      %Ecto.Changeset{data: %Template{}}

  """
  @spec change(Template.t(), map) :: Ecto.Changeset.t()
  def change(%Template{} = template, attrs \\ %{}) do
    Template.changeset(template, attrs)
  end

  @doc """
  Returns {pdf_content, pdf_name} where pdf_content
  uses evaluated print_default template using invoice
  data.
  """
  @spec pdf_content_and_name(Siwapp.Invoices.Invoice.t() | [Siwapp.Invoices.Invoice.t()]) ::
          {binary, binary}
  def pdf_content_and_name(%Siwapp.Invoices.Invoice{} = invoice) do
    {:ok, data} = ChromicPDF.print_to_pdf({:html, print_str_template(invoice)})

    {Base.decode64!(data), "#{invoice.series.code}-#{invoice.number}.pdf"}
  end

  def pdf_content_and_name(invoices) do
    to_print =
      {:html,
       Enum.reduce(invoices, "", fn invoice, acc -> print_str_template(invoice) <> acc end)}

    {
      to_print
      |> ChromicPDF.print_to_pdf()
      |> elem(1)
      |> Base.decode64!(),
      "invoices.pdf"
    }
  end

  @doc """
  Returns evaluated print_default template (html) using invoice data
  """
  @spec print_str_template(Siwapp.Invoices.Invoice.t()) :: binary
  def print_str_template(invoice) do
    template = get(:print_default).template
    string_template(template, invoice)
  end

  @doc """
  Returns {subject, email_body} where subject is defined by email_default template (struct)
  so as email_body, which is the evaluated email_template (html) using invoice data
  """
  @spec subject_and_email_body(Siwapp.Invoices.Invoice.t()) :: {binary, binary}
  def subject_and_email_body(invoice) do
    %Template{template: email_template, subject: subject_template} = get(:email_default)

    email_body = string_template(email_template, invoice)
    subject = EEx.eval_string(subject_template, series: invoice.series, number: invoice.number)
    {subject, email_body}
  end

  # Returns evaluated template using invoice data
  @spec string_template(binary, Siwapp.Invoices.Invoice.t()) :: binary
  defp string_template(template, invoice) do
    invoice = Siwapp.Invoices.with_virtual_fields(invoice)

    eval_data = [
      invoice: invoice,
      settings: Settings.current_bundle(),
      have_discount?: have_items_discount?(invoice.items),
      status: Invoices.status(invoice)
    ]

    EEx.eval_string(template, eval_data)
  end

  @spec have_items_discount?(list) :: boolean
  defp have_items_discount?([]) do
    false
  end

  defp have_items_discount?(items) do
    [h | t] = items

    if h.discount != 0 do
      true
    else
      have_items_discount?(t)
    end
  end

  @spec insert_new(map()) :: {:ok, Template.t()} | {:error, Ecto.Changeset.t()}
  defp insert_new(attrs) do
    %Template{}
    |> Template.changeset(attrs)
    |> Repo.insert()
  end

  @spec check_if_its_the_first(Template.t()) :: {:ok, Template.t()} | {:yes, Template.t()}
  defp check_if_its_the_first(template) do
    if length(list()) == 1, do: {:yes, template}, else: {:ok, template}
  end

  @spec update_by(Template.t(), String.t() | atom(), any()) ::
          {:ok, Template.t()} | {:error, Ecto.Changeset.t()}
  defp update_by(template, key, value) do
    template
    |> Template.changeset(%{key => value})
    |> Repo.update()
  end

  @spec change_default(:print_default | :email_default, Template.t()) ::
          {:ok, Template.t()} | {:error, Ecto.Changeset.t()}
  defp change_default(key, default_template) do
    for template <- list() do
      update_by(template, key, false)
    end

    update_by(default_template, key, true)
  end
end
