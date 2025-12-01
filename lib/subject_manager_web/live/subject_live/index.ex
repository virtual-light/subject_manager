defmodule SubjectManagerWeb.SubjectLive.Index do
  use SubjectManagerWeb, :live_view

  alias SubjectManager.Subjects
  alias SubjectManager.Subjects.Subject
  import SubjectManagerWeb.CustomComponents

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Subjects")
     |> assign(subjects: [])}
  end

  def handle_params(raw_params, _uri, socket) do
    case normalize_params(raw_params) do
      {:ok, params} ->
        {:noreply,
         socket
         |> assign(form: to_form(raw_params))
         |> assign(subjects: Subjects.list_subjects(params))}

      _ ->
        {:noreply, assign(socket, form: to_form(%{}))}
    end
  end

  def handle_event("apply_filters", params, socket) do
    params = Map.take(params, ~w(q position sort_by))
    {:noreply, push_patch(socket, to: ~p"/subjects?#{params}")}
  end

  def render(assigns) do
    ~H"""
    <div class="subject-index">
      <.filter_form form={@form} />

      <div class="subjects" id="subjects">
        <div id="empty" class="no-results only:block hidden">
          No subjects found. Try changing your filters.
        </div>
        <.subject :for={subject <- @subjects} subject={subject} dom_id={"subject-#{subject.id}"} />
      </div>
    </div>
    """
  end

  attr(:subject, SubjectManager.Subjects.Subject, required: true)
  attr(:dom_id, :string, required: true)

  def subject(assigns) do
    ~H"""
    <.link navigate={~p"/subjects/#{@subject}"} id={@dom_id}>
      <div class="card">
        <img src={Subjects.subject_image_path_or_placeholder(@subject)} />
        <h2>{@subject.name}</h2>
        <div class="details">
          <div class="team">
            {@subject.team}
          </div>
          <.badge status={@subject.position} />
        </div>
      </div>
    </.link>
    """
  end

  attr(:form, Phoenix.HTML.Form, required: true)

  def filter_form(assigns) do
    ~H"""
    <.form for={@form} id="filter-form" phx-change="apply_filters">
      <.input field={@form[:q]} placeholder="Search..." autocomplete="off" phx-debounce="350" />
      <.input
        type="select"
        field={@form[:position]}
        prompt="Position"
        options={[
          Forward: "forward",
          Midfielder: "midfielder",
          Winger: "winger",
          Defender: "defender",
          Goalkeeper: "goalkeeper"
        ]}
      />
      <.input
        type="select"
        field={@form[:sort_by]}
        prompt="Sort By"
        options={[
          Name: "name",
          Team: "team",
          Position: "position"
        ]}
      />

      <.link patch={~p"/subjects"}>
        Reset
      </.link>
    </.form>
    """
  end

  defp normalize_params(params) do
    types = %{
      q: :string,
      sort_by: Ecto.ParameterizedType.init(Ecto.Enum, values: [:name, :team, :position]),
      position:
        Ecto.ParameterizedType.init(Ecto.Enum, values: Ecto.Enum.values(Subject, :position))
    }

    permitted = Map.keys(types)

    changeset = Ecto.Changeset.cast({%{}, types}, params, permitted)

    if changeset.valid? do
      {:ok, Map.new(permitted, &{&1, Ecto.Changeset.get_change(changeset, &1)})}
    else
      :error
    end
  end
end
