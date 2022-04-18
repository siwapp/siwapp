defmodule Siwapp.TimerEvents do
  @moduledoc false
  use GenServer

  alias Siwapp.Accounts
  alias Siwapp.RecurringInvoices

  @spec start_link([]) :: {:ok, pid}
  def start_link([]) do
    GenServer.start_link(__MODULE__, nil)
  end

  @spec init(nil) :: {:ok, nil}
  def init(nil) do
    RecurringInvoices.generate_invoices()

    schedule_work_invoices()
    schedule_work_user_token()

    {:ok, nil}
  end

  @spec handle_info(:generate_invoices, nil) :: {:noreply, nil}
  def handle_info(:generate_invoices, nil) do
    RecurringInvoices.generate_invoices()
    schedule_work_invoices()
    {:noreply, nil}
  end

  @spec handle_info(:delete_user_token, nil) :: {:noreply, nil}
  def handle_info(:delete_user_token, nil) do
    Accounts.delete_user_token()
    schedule_work_user_token()
    {:noreply, nil}
  end

  @spec schedule_work_invoices :: reference()
  defp schedule_work_invoices do
    Process.send_after(self(), :generate_invoices, :timer.hours(24))
  end

  @spec schedule_work_user_token :: reference()
  defp schedule_work_user_token do
    Process.send_after(self(), :delete_user_token, :timer.hours(24 * 7))
  end
end
