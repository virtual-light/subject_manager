defmodule SubjectManagerWeb.SubjectLiveAdminTest do
  use SubjectManagerWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  @images_path "priv/static/images"

  @labels_to_fields_assoc Map.new(
                            ~w(name bio team position)a,
                            &{&1
                             |> Atom.to_string()
                             |> String.capitalize(), &1}
                          )

  describe "subjects list" do
    test "renders expected subjects", %{conn: conn} do
      subjects_params = [subject_params(), subject_params()]
      Enum.each(subjects_params, &submit_new_subject(conn, &1))

      subjects = list_subjects(conn)

      assert MapSet.new(subjects_params, &Map.take(&1, [:name, :team, :position])) ==
               MapSet.new(subjects)
    end
  end

  describe "create subject" do
    test "redirects on successful submit", %{conn: conn} do
      assert {:redirect, %{data: %{kind: :push, to: "/admin/subjects"}}} =
               submit_new_subject(conn)
    end

    test "doesn't redirect on failed submit", %{conn: conn} do
      assert {:stay, _} = submit_new_subject(conn, name: "")
    end

    test "creates new subject with expected values", %{conn: conn} do
      params = subject_params()

      assert {:ok, subject} = create_subject_with_params(conn, params)

      assert params == Map.delete(subject, :id)
    end

    @tag :slow
    test "saves avatar image on successful submit", %{conn: conn} do
      setup_images_cleanup_on_exit()

      params = subject_params()

      assert {:ok, {%{image_path: image_path}, file_content}} =
               create_subject_with_upload(conn, params: params)

      assert image_path != params.image_path

      assert File.read!(Path.join("priv/static", image_path)) == file_content
    end

    test "renders error when name is missing", %{conn: conn} do
      assert {:error, %{name: "can't be blank"}} = create_subject(conn, name: "")
    end

    test "renders error when team is missing", %{conn: conn} do
      assert {:error, %{team: "can't be blank"}} = create_subject(conn, team: "")
    end

    test "renders error when position is missing", %{conn: conn} do
      assert {:error, %{position: "can't be blank"}} = create_subject(conn, position: "")
    end

    test "renders error when position is invalid", %{conn: conn} do
      assert {:error, %{position: "is invalid"}} = create_subject(conn, position: :invalid)
    end

    test "doesn't save avatar image on failed submit", %{conn: conn} do
      initial_images = setup_images_cleanup_on_exit()

      {:error, _} = create_subject_with_upload(conn, name: "")

      assert File.ls!(@images_path) == initial_images
    end
  end

  describe "delete subject" do
    test "removes entry on current page", %{conn: conn} do
      subject1 = create_subject!(conn)
      subject2 = create_subject!(conn)

      html = delete_subject(conn, subject1.id)

      subject = Map.take(subject2, [:name, :team, :position])
      assert [subject] == parse_subjects(html)
    end

    test "removes subject entry completely", %{conn: conn} do
      subject1 = create_subject!(conn)
      subject2 = create_subject!(conn)

      delete_subject(conn, subject1.id)

      subject = Map.take(subject2, [:name, :team, :position])
      assert [subject] == list_subjects(conn)
    end

    test "removes associated avatar image with entry", %{conn: conn} do
      initial_images = setup_images_cleanup_on_exit()

      subject = create_subject_with_upload!(conn)

      delete_subject(conn, subject.id)

      assert File.ls!(@images_path) == initial_images
    end
  end

  describe "update subject" do
    test "redirects on successful submit", %{conn: conn} do
      %{id: id} = create_subject!(conn)

      assert {:redirect, %{data: %{kind: :push, to: "/admin/subjects"}}} =
               submit_subject_update(conn, id, %{name: "NewName"})
    end

    test "doesn't redirect on failed submit", %{conn: conn} do
      %{id: id} = create_subject!(conn)

      assert {:stay, _} = submit_subject_update(conn, id, %{name: ""})
    end

    test "changes subject fields to specified values", %{conn: conn} do
      params = %{
        name: "NewName",
        team: "NewTeam",
        position: :winger,
        bio: "Updated bio"
      }

      %{id: id} = create_subject!(conn)

      assert {:ok, subject} = update_subject(conn, id, params)

      assert params == Map.delete(subject, :image_path)
    end

    test "replaces avatar image on successful submit", %{conn: conn} do
      setup_images_cleanup_on_exit()

      file_path = "test/support/images/update_test.jpg"

      %{id: id, image_path: image_path} = create_subject_with_upload!(conn)

      assert {:ok, %{image_path: updated_image_path}} =
               update_subject_with_upload(conn, id, file_path)

      assert image_path != updated_image_path

      refute Path.basename(image_path) in File.ls!(@images_path)

      assert File.exists?(Path.join("priv/static", updated_image_path))
    end

    test "allows to remove previously uploaded avatar image", %{conn: conn} do
      initial_images = setup_images_cleanup_on_exit()
      subject = create_subject_with_upload!(conn)

      view = update_subject_view(conn, subject.id)

      view
      |> element(".upload-entry button")
      |> render_click()

      assert {:ok, updated_subject} = update_subject_with_view(view, subject.id, %{}, conn)

      assert updated_subject.image_path != subject.image_path

      assert initial_images == File.ls!(@images_path)
    end

    test "renders error when name is empty", %{conn: conn} do
      %{id: id} = create_subject!(conn)

      assert {:error, %{name: "can't be blank"}} = update_subject(conn, id, %{name: ""})
    end

    test "renders error when team is empty", %{conn: conn} do
      %{id: id} = create_subject!(conn)

      assert {:error, %{team: "can't be blank"}} = update_subject(conn, id, %{team: ""})
    end

    test "renders error when position is empty", %{conn: conn} do
      %{id: id} = create_subject!(conn)

      assert {:error, %{position: "can't be blank"}} = update_subject(conn, id, %{position: ""})
    end

    test "renders error when position is invalid", %{conn: conn} do
      %{id: id} = create_subject!(conn)

      assert {:error, %{position: "is invalid"}} = update_subject(conn, id, %{position: :invalid})
    end

    test "doesn't replace avatar image on failed submit", %{conn: conn} do
      setup_images_cleanup_on_exit()

      file_path = "test/support/images/update_test.jpg"

      %{id: id} = create_subject_with_upload!(conn)

      images_before_update = File.ls!(@images_path)

      {:error, _} = update_subject_with_upload(conn, id, file_path, %{name: ""})

      assert File.ls!(@images_path) == images_before_update
    end
  end

  defp subject_params(overrides \\ []) do
    number = unique_positive_integer()

    Map.merge(
      %{
        name: "Name#{number}",
        team: "Team#{number}",
        position: :forward,
        bio: "Bio text",
        image_path: "/images/placeholder.jpg"
      },
      Map.new(overrides)
    )
  end

  defp list_subjects(conn) do
    conn = get(conn, "/admin/subjects")
    {:ok, _view, html} = live(conn)

    parse_subjects(html)
  end

  defp delete_subject(conn, id) do
    conn = get(conn, "/admin/subjects")
    {:ok, view, _html} = live(conn)

    view
    |> element("#subject-#{id} td a", "Delete")
    |> render_click()
  end

  # -----------------------------------------------------------------------
  # Create
  # -----------------------------------------------------------------------

  defp create_subject_with_upload!(conn, params \\ []) do
    {:ok, {subject, _file_content}} = create_subject_with_upload(conn, params)
    subject
  end

  defp create_subject_with_upload(conn, params) do
    view = new_subject_view(conn)

    {file_path, params} = Keyword.pop(params, :file_path)
    {subject_params, overrides} = Keyword.pop(params, :params)

    subject_params =
      if is_nil(subject_params), do: subject_params(overrides), else: subject_params

    file_content = upload_image(view, file_path)

    with {:ok, subject} <- create_subject_with_params(conn, subject_params, view),
         do: {:ok, {subject, file_content}}
  end

  defp create_subject!(conn, params \\ []) do
    {:ok, subject} = create_subject(conn, params)
    subject
  end

  defp create_subject(conn, params) do
    {view, override} = Keyword.pop(params, :view)
    create_subject_with_params(conn, subject_params(override), view)
  end

  defp create_subject_with_params(conn, params, view \\ nil) do
    view = if is_nil(view), do: new_subject_view(conn), else: view

    case submit_subject(view, params) do
      {:redirect, redirect} ->
        {:ok, view, _html} = follow_redirect(redirect.follow, conn)

        show =
          view
          # relying on the fact that subjects are ordered by id in asc order
          |> element("table tr:last-child td:first-child")
          |> render_click()

        {:error, {:live_redirect, %{kind: :push, to: to}}} = show

        id =
          to
          |> Path.basename()
          |> String.to_integer()

        {:ok, _view, html} = follow_redirect(show, conn)

        {:ok,
         html
         |> parse_subject()
         |> Map.put(:id, id)}

      {:stay, html} ->
        {:error, parse_submit_errors(html)}
    end
  end

  defp submit_new_subject(conn, override \\ []) do
    conn
    |> new_subject_view()
    |> submit_subject(subject_params(override))
  end

  defp new_subject_view(conn) do
    conn = get(conn, "/admin/subjects/new")
    {:ok, view, _html} = live(conn)

    view
  end

  # -----------------------------------------------------------------------
  # Update
  # -----------------------------------------------------------------------

  defp update_subject_with_upload(conn, id, file_path, params \\ %{}) do
    view = update_subject_view(conn, id)

    upload_image(view, file_path)

    update_subject_with_view(view, id, params, conn)
  end

  defp update_subject(conn, id, params) do
    conn
    |> update_subject_view(id)
    |> update_subject_with_view(id, params, conn)
  end

  defp update_subject_with_view(view, id, params, conn) do
    case submit_subject(view, params) do
      {:redirect, _} ->
        conn = get(conn, "/subjects/#{id}")
        {:ok, _view, html} = live(conn)

        {:ok, parse_subject(html)}

      {:stay, html} ->
        {:error, parse_submit_errors(html)}
    end
  end

  defp submit_subject_update(conn, id, params) do
    conn
    |> update_subject_view(id)
    |> submit_subject(params)
  end

  defp update_subject_view(conn, id) do
    conn = get(conn, "/admin/subjects/#{id}/edit")
    {:ok, view, _html} = live(conn)

    view
  end

  # -----------------------------------------------------------------------
  # Submit & Upload
  # -----------------------------------------------------------------------

  defp submit_subject(view, params) do
    view
    |> element("form")
    |> render_submit(%{"subject" => stringify(params)})
    |> case do
      {:error, {:live_redirect, data}} = follow ->
        {:redirect, %{data: data, follow: follow}}

      content ->
        {:stay, content}
    end
  end

  defp parse_submit_errors(html) do
    items = Floki.find(html, "form div")

    Enum.reduce(items, %{}, fn item, acc ->
      case Floki.children(item) do
        [label, _input, error_block] ->
          label_name = label |> Floki.text() |> String.trim()
          name = Map.fetch!(@labels_to_fields_assoc, label_name)
          error = error_block |> Floki.text() |> String.trim()
          Map.put(acc, name, error)

        _ ->
          acc
      end
    end)
  end

  defp upload_image(view, file_path) do
    file_path = if is_nil(file_path), do: "test/support/images/test.jpg", else: file_path

    file_name = Path.basename(file_path)
    file_content = File.read!(file_path)

    avatar =
      file_input(view, "form", :avatar, [
        %{
          name: file_name,
          content: file_content
        }
      ])

    render_upload(avatar, file_name)
    file_content
  end

  # -----------------------------------------------------------------------
  # Parse
  # -----------------------------------------------------------------------

  defp parse_subjects(subject_list_html) do
    [head | rows] = Floki.find(subject_list_html, "table tr")

    fields =
      head
      |> Floki.children()
      |> Enum.drop(-1)
      |> Enum.map(fn label_block ->
        label = Floki.text(label_block)
        Map.fetch!(@labels_to_fields_assoc, label)
      end)

    Enum.map(rows, fn row ->
      values = Floki.find(row, "td div span:last-child")

      fields
      |> Enum.with_index()
      |> Map.new(fn {field, index} ->
        value = Enum.at(values, index) |> Floki.text() |> String.trim()
        value = if field == :position, do: String.to_existing_atom(value), else: value
        {field, value}
      end)
    end)
  end

  defp parse_subject(subject_show_html) do
    [{"div", _, [_link, {"div", _, [img, dl_block]}, outside_block]}] =
      Floki.find(subject_show_html, ".subject-show")

    [image_path] = Floki.attribute(img, "src")

    list = [outside_block | Floki.find(dl_block, ".flex")]

    parsed =
      Map.new(list, fn div ->
        [field, value] = Floki.children(div)
        {Floki.text(field), Floki.text(value)}
      end)

    %{
      name: Map.fetch!(parsed, "Name"),
      team: Map.fetch!(parsed, "Team"),
      bio: Map.fetch!(parsed, "Bio"),
      image_path: image_path,
      position: parsed |> Map.fetch!("Position") |> String.to_existing_atom()
    }
  end

  # -----------------------------------------------------------------------
  # Misc
  # -----------------------------------------------------------------------

  defp setup_images_cleanup_on_exit() do
    initial_images = File.ls!(@images_path)

    on_exit(fn ->
      images = File.ls!(@images_path)

      Enum.each(images -- initial_images, fn filename ->
        @images_path
        |> Path.join(filename)
        |> File.rm!()
      end)
    end)

    initial_images
  end

  defp unique_positive_integer, do: :erlang.unique_integer([:positive, :monotonic])

  defp stringify(params) do
    Map.new(params, fn {key, value} -> {Atom.to_string(key), to_string(value)} end)
  end
end
