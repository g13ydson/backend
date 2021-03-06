defmodule Re.Addresses do
  @moduledoc """
  Context for handling addresses
  """

  import Ecto.Query

  alias Re.{
    Address,
    Repo
  }

  alias __MODULE__.Neighborhoods

  defdelegate authorize(action, user, params), to: __MODULE__.Policy

  def data(params), do: Dataloader.Ecto.new(Re.Repo, query: &query/2, default_params: params)

  def query(query, %{has_admin_rights: true}), do: query

  def query(query, _), do: from(a in query, select_merge: %{street_number: nil})

  def get(params) do
    case Repo.get_by(
           Address,
           street: Map.get(params, "street") || Map.get(params, :street, ""),
           postal_code: Map.get(params, "postal_code") || Map.get(params, :postal_code, ""),
           street_number: Map.get(params, "street_number") || Map.get(params, :street_number, "")
         ) do
      nil -> {:error, :not_found}
      address -> {:ok, address}
    end
  end

  def get_by_id(id) do
    case Repo.get(Address, id) do
      nil -> {:error, :not_found}
      address -> {:ok, address}
    end
  end

  def insert_or_update(params) do
    params
    |> get()
    |> build_address(params)
    |> Address.changeset(params)
    |> Repo.insert_or_update()
  end

  def is_covered(address) do
    address
    |> Map.take(~w(state city neighborhood)a)
    |> Neighborhoods.is_covered()
  end

  defp build_address({:error, :not_found}, %{
         "street" => street,
         "postal_code" => postal_code,
         "street_number" => street_number
       }) do
    %Address{street: street, postal_code: postal_code, street_number: street_number}
  end

  defp build_address({:error, :not_found}, %{
         street: street,
         postal_code: postal_code,
         street_number: street_number
       }) do
    %Address{street: street, postal_code: postal_code, street_number: street_number}
  end

  defp build_address({:ok, address}, _), do: address
end
