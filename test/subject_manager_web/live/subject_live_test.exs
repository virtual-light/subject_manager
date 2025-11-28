defmodule SubjectManagerWeb.SubjectLiveTest do
  use SubjectManagerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SubjectManagerWeb.SubjectLiveHelper

  describe "subjects list" do
    test "renders expected subjects", %{conn: conn} do
      subjects = [create_subject!(conn), create_subject!(conn)]

      conn = get(conn, "/subjects")
      {:ok, _view, html} = live(conn)

      parsed_subjects = parse_subjects(html)

      assert MapSet.new(subjects, &Map.take(&1, [:name, :team, :position, :image_path])) ==
               MapSet.new(parsed_subjects)
    end

    test "filtered by position", %{conn: conn} do
      position = :defender

      create_subject!(conn)
      create_subject!(conn, position: position)

      conn = get(conn, "/subjects", position: Atom.to_string(position))
      {:ok, _view, html} = live(conn)

      assert [%{position: ^position}] = parse_subjects(html)
    end

    test "filtered by name", %{conn: conn} do
      name = "FindMe"

      create_subject!(conn)
      create_subject!(conn, name: name)

      conn = get(conn, "/subjects", q: name)
      {:ok, _view, html} = live(conn)

      assert [%{name: ^name}] = parse_subjects(html)
    end

    test "search by name", %{conn: conn} do
      create_subject!(conn)
      subject1 = create_subject!(conn, name: "John Doe")
      subject2 = create_subject!(conn, name: "Marry Doe The Second")

      conn = get(conn, "/subjects", q: "Doe")
      {:ok, _view, html} = live(conn)

      parsed_subjects = parse_subjects(html)

      subjects = [subject1, subject2]

      assert MapSet.new(subjects, & &1.name) == MapSet.new(parsed_subjects, & &1.name)
    end

    test "filtered exclusively by name and position", %{conn: conn} do
      name = "FindMe"
      position = :winger

      create_subject!(conn)
      create_subject!(conn, name: name)
      create_subject!(conn, position: position)
      create_subject!(conn, name: name, position: position)

      conn = get(conn, "/subjects", q: name, position: Atom.to_string(position))
      {:ok, _view, html} = live(conn)

      assert [%{name: ^name, position: ^position}] = parse_subjects(html)
    end

    test "ordered by name", %{conn: conn} do
      names = ["Curtis", "Zohran", "Andrew"]
      Enum.each(names, &create_subject!(conn, name: &1))

      conn = get(conn, "/subjects", sort_by: "name")
      {:ok, _view, html} = live(conn)

      parsed_subjects = parse_subjects(html)
      assert Enum.map(parsed_subjects, & &1.name) == Enum.sort(names)
    end

    test "ordered by team", %{conn: conn} do
      teams = ["Red", "Blue", "Purple"]
      Enum.each(teams, &create_subject!(conn, team: &1))

      conn = get(conn, "/subjects", sort_by: "team")
      {:ok, _view, html} = live(conn)

      parsed_subjects = parse_subjects(html)
      assert Enum.map(parsed_subjects, & &1.team) == Enum.sort(teams)
    end

    test "ordered by position", %{conn: conn} do
      positions = [:defender, :winger]
      Enum.each(positions, &create_subject!(conn, position: &1))

      conn = get(conn, "/subjects", sort_by: "position")
      {:ok, _view, html} = live(conn)

      parsed_subjects = parse_subjects(html)
      assert Enum.map(parsed_subjects, & &1.position) == Enum.sort(positions)
    end

    test "filtered by name and ordered by position", %{conn: conn} do
      create_subject!(conn)
      params = [%{name: "John Doe", position: :defender}, %{name: "John Cena", position: :winger}]

      Enum.each(params, &create_subject!(conn, Keyword.new(&1)))

      conn = get(conn, "/subjects", sort_by: "position", q: "John")
      {:ok, _view, html} = live(conn)

      parsed_subjects = parse_subjects(html)

      assert Enum.map(parsed_subjects, &Map.take(&1, [:name, :position])) ==
               Enum.sort_by(params, & &1.position)
    end

    test "empty on incorrect position query param", %{conn: conn} do
      create_subject!(conn)
      create_subject!(conn, position: :defender)

      conn = get(conn, "/subjects", position: "wrong_position_name")

      {:ok, _view, html} = live(conn)

      assert [] = parse_subjects(html)
    end

    test "empty on incorrect sort_by query param", %{conn: conn} do
      create_subject!(conn)

      conn = get(conn, "/subjects", sort_by: "wrong_sort")

      {:ok, _view, html} = live(conn)

      assert [] = parse_subjects(html)
    end
  end

  describe "show subject" do
    test "renders expected subject's fields", %{conn: conn} do
      subject = create_subject!(conn)
      conn = get(conn, "/subjects/#{subject.id}")

      {:ok, _view, html} = live(conn)

      assert Map.delete(subject, :id) == parse_subject(html)
    end

    test "redirects back to subjects", %{conn: conn} do
      create_subject!(conn)

      conn = get(conn, "/subjects")
      {:ok, view, _html} = live(conn)

      {:ok, view, _html} =
        view
        |> element("#subjects > :last-child")
        |> render_click()
        |> follow_redirect(conn)

      view
      |> element("a", "Back")
      |> render_click()

      assert_redirected(view, "/subjects")
    end

    test "redirects back to admin/subjects", %{conn: conn} do
      create_subject!(conn)

      conn = get(conn, "/admin/subjects")
      {:ok, view, _html} = live(conn)

      {:ok, view, _html} =
        view
        |> get_redirect_to_last_subject_for_admin()
        |> follow_redirect(conn)

      view
      |> element("a", "Back")
      |> render_click()

      assert_redirected(view, "/admin/subjects")
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
      [image_path] = children |> Floki.find("img") |> Floki.attribute("src")

      %{
        name: children |> Floki.find("h2") |> Floki.text(),
        team: team_block |> Floki.text() |> String.trim(),
        position: position_block |> Floki.text() |> String.trim() |> String.to_existing_atom(),
        image_path: image_path
      }
    end)
  end

  # the largest INTEGER
  defp unknown_id, do: 9_223_372_036_854_775_807
end
