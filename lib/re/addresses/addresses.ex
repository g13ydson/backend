defmodule Re.Addresses do
  @moduledoc """
  Context for handling addresses
  """

  alias Re.{
    Address,
    Repo
  }

  def find_or_create(address_params) do
    case find_unique(address_params) do
      nil ->
        insert(address_params)

      address ->
        address
        |> Address.changeset(address_params)
        |> Repo.update()
    end
  end

  defp find_unique(address_params) do
    Repo.get_by(
      Address,
      street: address_params["street"] || "",
      postal_code: address_params["postal_code"] || "",
      street_number: address_params["street_number"] || ""
    )
  end

  def update(listing, address_params) do
    address =
      listing
      |> Repo.preload(:address)
      |> Map.get(:address)

    if changed?(address, address_params) do
      find_or_create(address_params)
    else
      {:ok, address}
    end
  end

  defp changed?(address, address_params) do
    %{changes: changes} = Address.changeset(address, address_params)

    changes != %{}
  end

  defp insert(address_params) do
    %Address{}
    |> Address.changeset(address_params)
    |> Repo.insert()
  end
end
