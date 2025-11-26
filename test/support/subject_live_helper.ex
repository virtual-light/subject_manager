defmodule SubjectManagerWeb.SubjectLiveHelper do
  import Phoenix.LiveViewTest
  import Phoenix.ConnTest
  import SubjectManagerWeb.ConnCase

  alias SubjectManager.Subjects.Subject

  @endpoint SubjectManagerWeb.Endpoint

  @type view :: %Phoenix.LiveViewTest.View{}
  @type overrides :: [
          name: Subject.name(),
          team: String.t(),
          position: Subject.position(),
          bio: String.t()
        ]

  @type subject_create_otps :: [{:view, view()} | overrides()]

  @type subject :: %{
          id: integer(),
          name: String.t(),
          team: String.t(),
          position: atom(),
          bio: String.t(),
          image_path: String.t()
        }

  @type parsed_subject :: %{
          name: String.t(),
          team: String.t(),
          position: atom(),
          bio: String.t(),
          image_path: String.t()
        }

  @type subject_params :: %{
          name: Subject.name(),
          team: String.t(),
          position: Subject.position(),
          bio: String.t()
        }

  @type errors :: %{
          optional(:name) => String.t(),
          optional(:team) => String.t(),
          optional(:position) => String.t()
        }

  @type follow_redirect_opts :: %{to: Path.t()}
  @type follow_redirect :: {:error, {:live_redirect, follow_redirect_opts()}}
  @type html() :: binary()

  @spec subject_params(overrides()) :: subject_params()
  def subject_params(overrides \\ []) do
    number = unique_positive_integer()

    Map.merge(
      %{
        name: "Name#{number}",
        team: "Team#{number}",
        position: :forward,
        bio: "Bio text"
      },
      Map.new(overrides)
    )
  end

  @spec create_subject!(Plug.Conn.t(), subject_create_otps()) :: subject()
  def create_subject!(conn, params \\ []) do
    {:ok, subject} = create_subject(conn, params)
    subject
  end

  @spec create_subject(Plug.Conn.t(), subject_create_otps()) ::
          {:ok, subject()} | {:error, errors()}
  def create_subject(conn, params) do
    {view, override} = Keyword.pop(params, :view)
    create_subject_with_params(conn, subject_params(override), view)
  end

  @spec create_subject_with_params(Plug.Conn.t(), subject_params(), view() | nil) ::
          {:ok, subject()} | {:error, errors()}
  def create_subject_with_params(conn, params, view \\ nil) do
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

  @spec new_subject_view(Plug.Conn.t()) :: view()
  def new_subject_view(conn) do
    conn = get(conn, "/admin/subjects/new")
    {:ok, view, _html} = live(conn)

    view
  end

  @spec submit_subject(view(), subject_params()) ::
          {:redirect, %{data: follow_redirect_opts(), follow: follow_redirect()}}
          | {:stay, binary()}
  def submit_subject(view, params) do
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

  @spec parse_submit_errors(Floki.html_tree() | Floki.html_node()) :: errors()
  def parse_submit_errors(html) do
    items = Floki.find(html, "form div")

    Enum.reduce(items, %{}, fn item, acc ->
      case Floki.children(item) do
        [label, _input, error_block] ->
          label_name = label |> Floki.text() |> String.trim()
          name = Map.fetch!(labels_to_fields_assoc(), label_name)
          error = error_block |> Floki.text() |> String.trim()
          Map.put(acc, name, error)

        _ ->
          acc
      end
    end)
  end

  @spec parse_subject(Floki.html_tree() | Floki.html_node()) :: parsed_subject()
  def parse_subject(subject_show_html) do
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

  @spec labels_to_fields_assoc :: %{
          required(String.t()) => :name | :bio | :team | :position
        }
  def labels_to_fields_assoc do
    Map.new(
      ~w(name bio team position)a,
      &{&1
       |> Atom.to_string()
       |> String.capitalize(), &1}
    )
  end

  @spec unique_positive_integer :: pos_integer()
  def unique_positive_integer, do: :erlang.unique_integer([:positive, :monotonic])

  defp stringify(params) do
    Map.new(params, fn {key, value} -> {Atom.to_string(key), to_string(value)} end)
  end
end
