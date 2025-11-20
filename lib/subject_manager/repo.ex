defmodule SubjectManager.Repo do
  use Ecto.Repo,
    otp_app: :subject_manager,
    adapter: Ecto.Adapters.SQLite3
end
