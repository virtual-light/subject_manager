defmodule SubjectManager.Subjects do
  alias SubjectManager.Subjects.Subject
  alias SubjectManager.Repo

  def list_subjects do
    Repo.all(Subject)
  end
end
