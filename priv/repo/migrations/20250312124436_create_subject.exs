defmodule SubjectManager.Repo.Migrations.CreateSubject do
  use Ecto.Migration

  def change do
    create table(:subjects) do
      add :name, :string
      add :team, :text
      add :position, :string
      add :bio, :string
      add :image_path, :string

      timestamps(type: :utc_datetime)
    end
  end
end
