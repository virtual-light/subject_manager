defmodule SubjectManagerWeb.SubjectLive.Show do
  use SubjectManagerWeb, :live_view

  alias SubjectManager.Subjects

  @impl true
  def render(assigns) do
    ~H"""
    <div class="subject-show">
      <.link
        navigate={@return_to}
        class="mb-4 inline-block px-4 py-2 text-sm font-semibold text-blue-600 hover:text-blue-800 border border-blue-600 rounded hover:bg-blue-50 transition duration-150"
      >
        &larr; Back to Subjects
      </.link>

      <div class="subject md:grid md:grid-cols-3 md:gap-8">
        <img
          src={Subjects.subject_image_path_or_placeholder(@subject)}
          class="h-40 w-70 object-cover transition duration-500 group-hover:scale-105 sm:h-72"
        />

        <.list>
          <:item title="Name">{@subject.name}</:item>
          <:item title="Team">{@subject.team}</:item>
          <:item title="Position">{@subject.position}</:item>
        </.list>
      </div>

      <div class="mt-8 pt-4 border-t">
        <h3 class="text-lg mb-2">Bio</h3>
        <p class="text-gray-600">{@subject.bio}</p>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => str} = params, _session, socket) do
    case Integer.parse(str) do
      {id, ""} when id > 0 ->
        {:ok,
         socket
         |> assign(:page_title, "Show Subjects")
         |> assign(:return_to, return_to(params))
         |> assign(:subject, Subjects.get!(id))}

      _ ->
        raise Plug.BadRequestError, message: "Invalid ID provided"
    end
  end

  defp return_to(%{"return_to" => "admin"}), do: ~p"/admin/subjects"
  defp return_to(_), do: ~p"/subjects"
end
