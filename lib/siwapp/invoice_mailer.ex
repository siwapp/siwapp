defmodule Siwapp.InvoiceMailer do
  @moduledoc """
  This module manages building a invoice email ready to be delivered
  """
  import Swoosh.Email

  alias Siwapp.Settings
  alias Siwapp.Templates
  alias Swoosh.Attachment

  @doc """
  Given an invoice, returns {:ok, email} if it's possible
  to build email struct from data. Otherwise, {:error, msg}
  """
  @spec build_invoice_email(Siwapp.Invoices.Invoice.t()) ::
          {:ok, Swoosh.Email.t()} | {:error, binary}
  def build_invoice_email(invoice) do
    {subject, email_body} = Templates.subject_and_email_body(invoice)

    email =
      new()
      |> to({invoice.name, invoice.email})
      |> from({Settings.value(:company), Settings.value(:company_email)})
      |> subject(subject)
      |> html_body(email_body)
      |> attachment(attachment_struct(invoice))

    {:ok, email}
  rescue
    _e in ArgumentError ->
      {:error, "Sending email is impossible if no email address
      is provided. Please edit the invoice and fill email field if
      you want to be able to send it"}
  end

  @spec attachment_struct(Siwapp.Invoices.Invoice.t()) :: Attachment.t()
  defp attachment_struct(invoice) do
    {pdf_content, pdf_name} = Templates.pdf_content_and_name(invoice)

    Attachment.new(
      {:data, pdf_content},
      filename: pdf_name,
      content_type: "application/pdf",
      type: :attachment
    )
  end
end
