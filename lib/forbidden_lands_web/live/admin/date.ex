defmodule ForbiddenLandsWeb.Live.Admin.Date do
  @moduledoc """
  Dashboard of an instance.
  """

  use ForbiddenLandsWeb, :live_component

  alias ForbiddenLands.Calendar
  alias ForbiddenLands.Instances.{Event, Stronghold, Instances}
  alias ForbiddenLandsWeb.Endpoint

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> assign(show_more?: false)
      |> assign(playlists: ForbiddenLands.Music.Mood.playlists())

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    # MAYBE ADD:
    # stats. (?)

    ~H"""
    <div class="p-6">
      <section class="flex flex-col gap-5">
        <.button phx-click="move" phx-target={@myself} phx-value-amount={1} color={:blue}>
          <%= dgettext("admin", "Passer au prochain quarter") %>
        </.button>
        <.button phx-click="toggle_stronghold" phx-target={@myself}>
          <%= dgettext("admin", "Afficher/cacher le château") %>
        </.button>

        <div class="flex gap-3">
          <.button
            :for={{playlist, _music} <- @playlists}
            phx-click="update_playlist"
            phx-value-playlist={playlist}
            phx-target={@myself}
          >
            <%= playlist %>
          </.button>
        </div>

        <button
          type="button"
          class="flex gap-2 justify-center opacity-50 hover:opacity-100"
          phx-click="show_more"
          phx-target={@myself}
        >
          <%= dgettext("admin", "Plus d'options") %>
          <Heroicons.chevron_double_up class={["h-6 w-6 transition-all duration-500", not @show_more? && "rotate-180"]} />
        </button>

        <div :if={@show_more?} class="flex flex-col gap-3">
          <.button phx-click="move" phx-target={@myself} phx-value-amount={4}>
            <%= dgettext("admin", "Avancer d'un jour") %>
          </.button>
          <.button phx-click="move" phx-target={@myself} phx-value-amount={28}>
            <%= dgettext("admin", "Avancer d'une semaine") %>
          </.button>
          <.button phx-click="move" phx-target={@myself} phx-value-amount={-1} color={:red}>
            <%= dgettext("admin", "Reculer d'un quarter") %>
          </.button>
        </div>
      </section>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("show_more", _params, socket) do
    {:noreply, assign(socket, :show_more?, not socket.assigns.show_more?)}
  end

  def handle_event("toggle_stronghold", _params, %{assigns: %{topic: topic}} = socket) do
    Endpoint.broadcast(topic, "toggle_stronghold", %{})
    {:noreply, socket}
  end

  def handle_event("update_playlist", %{"playlist" => playlist}, %{assigns: %{topic: topic}} = socket) do
    Endpoint.broadcast(topic, "update_playlist", %{playlist: playlist})
    {:noreply, socket}
  end

  def handle_event(
        "move",
        %{"amount" => amount},
        %{assigns: %{topic: topic, instance: instance, calendar: calendar}} = socket
      ) do
    new_calendar = Calendar.add(calendar, String.to_integer(amount), :quarter)
    weeks_diff = compute_weeks_diff(calendar, new_calendar)

    instance =
      if not is_nil(instance.stronghold) and weeks_diff > 0 do
        rules =
          instance.resource_rules
          |> Enum.map(fn %{name: name, type: type, amount: amount} ->
            gettext_data = [
              name: String.capitalize(name),
              amount: abs(amount * weeks_diff),
              resource: Stronghold.resource_name(type, amount)
            ]

            if amount > 0,
              do: dgettext("events", "— %{name} produit %{amount} %{resource}", gettext_data),
              else: dgettext("events", "— %{name} consomme %{amount} %{resource}", gettext_data)
          end)
          |> Enum.join("\r\n")

        event =
          Event.create(%Event{}, %{
            "human_datequarter" => Calendar.to_datequarter(Calendar.start_of(new_calendar, :week)),
            "type" => "automatic",
            "title" => dngettext("events", "1 semaine passe", "%{count} semaines passent", weeks_diff),
            "description" =>
              dgettext("events", "Récapitulatif des ressources du château: \r\n\r\n%{rules}", rules: rules)
          })

        stronghold_params =
          Enum.reduce(Stronghold.resource_fields(), %{}, fn field, params ->
            current_amount = Map.get(params, Atom.to_string(field), Map.get(instance.stronghold, field))

            new_amount =
              Enum.reduce(instance.resource_rules, current_amount, fn %{type: type, amount: amount}, total ->
                if type == field, do: total + amount * weeks_diff, else: total
              end)

            new_amount = Enum.max([0, new_amount])

            Map.put(params, Atom.to_string(field), new_amount)
          end)

        with {:ok, _instance} = Instances.add_event(instance, event),
             changeset <- Map.put(Stronghold.changeset(instance.stronghold, stronghold_params), :action, :update),
             true <- changeset.valid?,
             {:ok, instance} = Instances.update(instance, %{"stronghold" => changeset.changes}) do
          instance
        else
          _ -> instance
        end
      else
        instance
      end

    case Instances.update(instance, %{current_date: new_calendar.count.quarters}) do
      {:ok, _instance} ->
        Endpoint.broadcast(topic, "update", %{})
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error: (#{inspect(reason)})")}
    end
  end

  defp compute_weeks_diff(old_calendar, new_calendar) do
    days_diff = old_calendar.day.number + abs(new_calendar.count.days - old_calendar.count.days) - 1
    floor(days_diff / 7)
  end
end
