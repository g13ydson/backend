defmodule Re.Image do
  @moduledoc """
  Module for listing images.
  """
  use Ecto.Schema

  import Ecto.Changeset

  schema "images" do
    field :filename, :string
    field :position, :integer
    field :is_active, :boolean, default: true
    field :description, :string

    belongs_to :listing, Re.Listing

    timestamps()
  end

  @create_required ~w(filename)a
  @create_optional ~w(position description)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @create_required ++ @create_optional)
    |> cast_assoc(:listing)
    |> validate_required(@create_required)
  end

  @update_required ~w()a
  @update_optional ~w(position description)a

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @update_required ++ @update_optional)
    |> validate_required(@update_required)
  end

  @deactivate_required ~w(is_active)a
  @deactivate_optional ~w()a

  def deactivate_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @deactivate_required ++ @deactivate_optional)
    |> validate_required(@deactivate_required)
  end
end
