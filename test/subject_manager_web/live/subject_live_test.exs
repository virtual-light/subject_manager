defmodule SubjectManagerWeb.SubjectLiveTest do
  use SubjectManagerWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias SubjectManager.Subjects.Subject

  describe "subjects list" do
    test "renders expected subjects", %{conn: conn} do
      subjects = [insert_subject!(), insert_subject!()]

      conn = get(conn, "/subjects")
      {:ok, _view, html} = live(conn)

      parsed_sbujects = parse_subjects(html)

      assert MapSet.new(subjects, &Map.take(&1, [:name, :team, :position])) ==
               MapSet.new(parsed_sbujects)
    end
  end

  defp parse_subjects(html) do
    cards = Floki.find(html, ".card")

    Enum.map(cards, fn card ->
      children = Floki.children(card)
      [{"div", _, [team_block, position_block]}] = Floki.find(children, ".details")

      %{
        name: children |> Floki.find("h2") |> Floki.text(),
        team: team_block |> Floki.text() |> String.trim(),
        position: position_block |> Floki.text() |> String.trim() |> String.to_existing_atom()
      }
    end)
  end

  defp insert_subject!(opts \\ []) do
    subject = Keyword.get_lazy(opts, :subject, &subject/0)

    %Subject{}
    |> Ecto.Changeset.change(subject)
    |> SubjectManager.Repo.insert!()
  end

  defp subject(overrides \\ []) do
    number = unique_positive_integer()

    Map.merge(
      %{
        name: "Name#{number}",
        team: "Team#{number}",
        position: :forward,
        bio: "",
        image_path: "/images/placeholder.jpg"
      },
      Map.new(overrides)
    )
  end

  defp unique_positive_integer, do: :erlang.unique_integer([:positive, :monotonic])
end
