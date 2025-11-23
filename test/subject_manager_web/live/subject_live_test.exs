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

    test "filtered by position", %{conn: conn} do
      position = :defender

      insert_subject!()
      insert_subject!(position: position)

      conn = get(conn, "/subjects", position: Atom.to_string(position))
      {:ok, _view, html} = live(conn)

      assert [%{position: ^position}] = parse_subjects(html)
    end

    test "filtered by name", %{conn: conn} do
      name = "FindMe"

      insert_subject!()
      insert_subject!(name: name)

      conn = get(conn, "/subjects", q: name)
      {:ok, _view, html} = live(conn)

      assert [%{name: ^name}] = parse_subjects(html)
    end

    test "search by name", %{conn: conn} do
      insert_subject!()
      subject1 = insert_subject!(name: "John Doe")
      subject2 = insert_subject!(name: "Marry Doe The Second")

      conn = get(conn, "/subjects", q: "Doe")
      {:ok, _view, html} = live(conn)

      parsed_subjects = parse_subjects(html)

      subjects = [subject1, subject2]

      assert MapSet.new(subjects, & &1.name) == MapSet.new(parsed_subjects, & &1.name)
    end

    test "filtered exclusively by name and position", %{conn: conn} do
      name = "FindMe"
      position = :winger

      insert_subject!()
      insert_subject!(name: name)
      insert_subject!(position: position)
      insert_subject!(name: name, position: position)

      conn = get(conn, "/subjects", q: name, position: Atom.to_string(position))
      {:ok, _view, html} = live(conn)

      assert [%{name: ^name, position: ^position}] = parse_subjects(html)
    end

    test "ordered by name", %{conn: conn} do
      names = ["Curtis", "Zohran", "Andrew"]
      Enum.each(names, &insert_subject!(name: &1))

      conn = get(conn, "/subjects", sort_by: "name")
      {:ok, _view, html} = live(conn)

      parsed_subjects = parse_subjects(html)
      assert Enum.map(parsed_subjects, & &1.name) == Enum.sort(names)
    end

    test "ordered by team", %{conn: conn} do
      teams = ["Red", "Blue", "Purple"]
      Enum.each(teams, &insert_subject!(team: &1))

      conn = get(conn, "/subjects", sort_by: "team")
      {:ok, _view, html} = live(conn)

      parsed_subjects = parse_subjects(html)
      assert Enum.map(parsed_subjects, & &1.team) == Enum.sort(teams)
    end

    test "ordered by position", %{conn: conn} do
      positions = [:defender, :winger]
      Enum.each(positions, &insert_subject!(position: &1))

      conn = get(conn, "/subjects", sort_by: "position")
      {:ok, _view, html} = live(conn)

      parsed_subjects = parse_subjects(html)
      assert Enum.map(parsed_subjects, & &1.position) == Enum.sort(positions)
    end

    test "filtered by name and ordered by position", %{conn: conn} do
      insert_subject!()
      params = [%{name: "John Doe", position: :defender}, %{name: "John Cena", position: :winger}]

      Enum.each(params, &insert_subject!(Keyword.new(&1)))

      conn = get(conn, "/subjects", sort_by: "position", q: "John")
      {:ok, _view, html} = live(conn)

      parsed_subjects = parse_subjects(html)

      assert Enum.map(parsed_subjects, &Map.take(&1, [:name, :position])) ==
               Enum.sort_by(params, & &1.position)
    end

    test "empty on incorrect position query param", %{conn: conn} do
      insert_subject!()
      insert_subject!(position: :defender)

      conn = get(conn, "/subjects", position: "wrong_position_name")

      {:ok, _view, html} = live(conn)

      assert [] = parse_subjects(html)
    end

    test "empty on incorrect sort_by query param", %{conn: conn} do
      insert_subject!()

      conn = get(conn, "/subjects", sort_by: "wrong_sort")

      {:ok, _view, html} = live(conn)

      assert [] = parse_subjects(html)
    end
  end

  describe "show subject" do
    test "renders expected subject's fields", %{conn: conn} do
      subject = insert_subject!()
      conn = get(conn, "/subjects/#{subject.id}")

      {:ok, _view, html} = live(conn)

      assert Map.take(subject, [:name, :team, :position]) == parse_subject(html)
    end

    test "renders back to subjects", %{conn: conn} do
      %{id: id} = insert_subject!()
      conn = get(conn, "/subjects/#{id}")

      {:ok, view, _html} = live(conn)

      assert has_element?(view, "a", "Back")

      view
      |> element("a", "Back")
      |> render_click()

      assert_redirected(view, "/subjects")
    end

    test "returns 404 for non-existing id", %{conn: conn} do
      assert_error_sent :not_found, fn -> get(conn, "/subjects/#{unknown_id()}") end
    end

    test "returns 400 for invalid id", %{conn: conn} do
      assert_error_sent :bad_request, fn -> get(conn, "/subjects/12fail34}") end
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

  defp parse_subject(html) do
    [{"div", _, [_img, list]}] = Floki.find(html, ".subject")

    parsed =
      list
      |> Floki.find(".flex")
      |> Map.new(fn div ->
        [name, value] = Floki.children(div)
        {Floki.text(name), Floki.text(value)}
      end)

    %{
      name: Map.fetch!(parsed, "Name"),
      team: Map.fetch!(parsed, "Team"),
      position: parsed |> Map.fetch!("Position") |> String.to_existing_atom()
    }
  end

  defp insert_subject!(opts \\ nil) do
    subject = if is_nil(opts), do: subject(), else: subject(opts)

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

  # the largest INTEGER
  defp unknown_id, do: 9_223_372_036_854_775_807
end
