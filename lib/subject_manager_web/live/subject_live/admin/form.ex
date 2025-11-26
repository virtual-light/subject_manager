defmodule SubjectManagerWeb.SubjectLive.Admin.Form do
  use SubjectManagerWeb, :live_view

  alias SubjectManager.Subjects

  @impl true
  def render(assigns) do
    ~H"""
    <.form for={@form} id="subject-form" phx-change="validate" phx-submit="save" class="space-y-4">
      <.input field={@form[:name]} type="text" label="Name" />
      <.input field={@form[:team]} type="text" label="Team" />
      <.input field={@form[:position]} type="select" label="Position" options={@positions} />
      <.input field={@form[:bio]} type="textarea" label="Bio" />
      <%= if @subject.image_path && @uploads.avatar.entries == [] do %>
        <div class="upload-entry" flex items-start gap-2>
          <img src={@subject.image_path} width="100" />
          <button
            type="button"
            phx-click="drop-avatar"
            aria-label="cancel"
            class="text-xl leading-none"
          >
            &times;
          </button>
        </div>
      <% end %>

      <%= for entry <- @uploads.avatar.entries do %>
        <div class="upload-entry flex items-start gap-2">
          <.live_img_preview entry={entry} width="100" />
          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            aria-label="cancel"
            class="text-xl leading-none"
          >
            &times;
          </button>
          <p :for={err <- upload_errors(@uploads.avatar, entry)} class="text-red-600 text-sm mt-2">
            {error_to_string(err)}
          </p>
        </div>
      <% end %>
      <.live_file_input upload={@uploads.avatar} />
      <footer class="mt-6">
        <.button phx-disable-with="Saving...">Save</.button>
        <.link navigate={~p"/admin/subjects"}>
          <.button>Cancel</.button>
        </.link>
      </footer>
    </.form>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    subject = Subjects.get!(id)

    socket
    |> assign(:page_title, "Edit Subject")
    |> assign(:subject, subject)
    |> assign(:form, to_form(changeset(subject)))
    |> allow_upload(:avatar, accept: ~w(.jpg .jpeg ), max_entries: 1)
    |> assign(:positions, positions())
  end

  defp apply_action(socket, :new, _params) do
    subject = %Subjects.Subject{}

    socket
    |> assign(:page_title, "New Subject")
    |> assign(:subject, %{subject | image_path: nil})
    |> assign(:form, to_form(changeset(subject)))
    |> allow_upload(:avatar, accept: ~w(.jpg .jpeg ), max_entries: 1)
    |> assign(:positions, positions())
  end

  @impl true
  def handle_event("validate", %{"subject" => subject_params}, socket) do
    subject = changeset(socket.assigns.subject, subject_params)
    {:noreply, assign(socket, form: to_form(subject, action: :validate))}
  end

  def handle_event("save", %{"subject" => subject_params}, socket) do
    save_subject(socket, socket.assigns.live_action, subject_params)
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("drop-avatar", _, socket) do
    subject = socket.assigns.subject
    {:noreply, assign(socket, :subject, %{subject | image_path: nil})}
  end

  defp save_subject(socket, :new, subject_params) do
    case create_subject(socket, subject_params) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Subject created successfully")
         |> push_navigate(to: ~p"/admin/subjects")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}

      {:error, validation_error} ->
        raise Plug.BadRequestError, message: validation_error
    end
  end

  defp save_subject(socket, :edit, subject_params) do
    case update_subject(socket, subject_params) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Subject updated successfully")
         |> push_navigate(to: ~p"/admin/subjects")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}

      {:error, validation_error} ->
        raise Plug.BadRequestError, message: validation_error
    end
  end

  defp create_subject(socket, subject_params) do
    with {:ok, params} <- validate_subject_params(%Subjects.Subject{}, subject_params),
         {:ok, image_path} <- fetch_avatar(socket, params.name) do
      params
      |> Map.put(:image_path, image_path)
      |> Subjects.create()

      :ok
    end
  end

  defp update_subject(socket, subject_params) do
    subject = socket.assigns.subject

    with {:ok, params} <- validate_subject_params(subject, subject_params),
         {:ok, image_path} <- fetch_avatar(socket, params.name) do
      Subjects.update!(subject.id, Map.put(params, :image_path, image_path))

      :ok
    end
  end

  defp validate_subject_params(subject, raw_params) do
    case changeset(subject, raw_params) do
      %{valid?: false} = changeset ->
        {:error, changeset}

      changeset ->
        params =
          changeset
          |> Ecto.Changeset.apply_changes()
          |> Map.take(~w(name team position bio)a)

        {:ok, params}
    end
  end

  defp changeset(subject, params \\ %{}) do
    subject
    |> Ecto.Changeset.cast(params, ~w(name team position bio)a)
    |> Ecto.Changeset.validate_required(~w(name team position)a)
  end

  defp fetch_avatar(socket, subject_name) do
    case uploaded_entries(socket, :avatar) do
      {[], _} ->
        {:ok, nil}

      {[entry], _} ->
        path = save_file(entry, subject_name, socket)
        %{size: size} = File.stat!(path)

        if size >= 8_000_000 do
          File.rm!(path)
          {:error, "File is too large"}
        else
          {:ok, ~p"/images/#{Path.basename(path)}"}
        end

      _ ->
        {:error, "Too many files"}
    end
  end

  defp save_file(entry, subject_name, socket) do
    consume_uploaded_entry(socket, entry, fn %{path: path} ->
      dest = Path.join("priv/static/images", new_filename(subject_name, entry.client_name))
      File.cp!(path, dest)
      {:ok, dest}
    end)
  end

  defp new_filename(subject_name, client_filename) do
    timestamp = System.os_time()
    random_string = Base.encode16(:crypto.strong_rand_bytes(8))
    filename = "#{subject_name}_#{timestamp}_#{random_string}"

    case Path.extname(client_filename) do
      "" ->
        filename

      ext ->
        "#{filename}#{ext}"
    end
  end

  defp positions do
    Enum.map(Subjects.positions(), fn {key, value} -> {String.capitalize(value), key} end)
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
