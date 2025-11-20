defmodule SubjectManager.Subjects.Subject do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subjects" do
    field :name, :string
    field :team, :string
    field :position, Ecto.Enum, values: [:forward, :midfielder, :winger, :defender, :goalkeeper]
    field :bio, :string
    field :image_path, :string, default: "/images/placeholder.jpg"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [:name, :team, :position, :bio, :image_path])
    |> validate_required([:name, :team, :position, :bio, :image_path])
    |> validate_length(:name, min: 3)
    |> validate_length(:description, min: 10)
  end
end
