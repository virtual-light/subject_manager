defmodule SubjectManagerWeb.SubjectLive.Admin.Index do
  use SubjectManagerWeb, :live_view

  alias SubjectManager.Subjects

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_title: "Subjects")
      |> assign(form: to_form(%{}))

    {:ok, assign(socket, :subjects, Subjects.list_subjects())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: assigns} = socket) do
    if is_integer(id) and id > 0 do
      subjects = assigns.subjects
      Subjects.delete!(id)

      {:noreply, assign(socket, :subjects, without_one(subjects, id))}
    else
      raise Plug.BadRequestError, message: "Invalid ID provided"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Subjects
      <:actions>
        <.link navigate={~p"/admin/subjects/new"}>
          <.icon name="hero-plus" /> New Subject
        </.link>
      </:actions>
    </.header>

    <.table
      id="subjects"
      rows={@subjects}
      row_id={fn subject -> "subject-#{subject.id}" end}
      row_click={fn subject -> JS.navigate(~p"/subjects/#{subject}") end}
    >
      <:col :let={subject} label="Name">{subject.name}</:col>
      <:col :let={subject} label="Team">{subject.team}</:col>
      <:col :let={subject} label="Position">{subject.position}</:col>
      <:action :let={subject}>
        <div class="sr-only">
          <.link navigate={~p"/subjects/#{subject}"}>Show</.link>
        </div>
        <.link navigate={~p"/admin/subjects/#{subject}/edit"}>Edit</.link>
      </:action>
      <:action :let={subject}>
        <.link
          phx-click={JS.push("delete", value: %{id: subject.id}) |> hide("##{subject.id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>
    """
  end

  defp without_one(items, id, rem \\ [])
  defp without_one([], _, acc), do: Enum.reverse(acc)
  defp without_one([%{id: id} | rem], id, acc), do: Enum.reverse(acc) ++ rem
  defp without_one([item | rem], id, acc), do: without_one(rem, id, [item | acc])
end
