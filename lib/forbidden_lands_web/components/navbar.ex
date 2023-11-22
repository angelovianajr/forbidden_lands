defmodule ForbiddenLandsWeb.Components.Navbar do
  @moduledoc """
  """

  use ForbiddenLandsWeb, :html

  @spec navbar(assigns :: map()) :: Phoenix.LiveView.Rendered.t()
  def navbar(assigns) do
    ~H"""
    <header class="bg-white text-slate-900 border-b md:border-none py-3 px-2 shadow-md flex justify-between print:hidden">
      <nav class="flex gap-2">
        <h1 class="font-bold py-2 px-3 pr-4 border-r text-brand">
          <span class="hidden md:inline">
            <%= dgettext("app", "Forbidden Lands Companion") %>
          </span>
          <span class="md:hidden">
            <%= dgettext("app", "FLC") %>
          </span>
        </h1>
        <.link navigate={~p"/#{Gettext.get_locale()}/"} class={link_classes()}>
          <%= dgettext("app", "Adventures") %>
        </.link>
        <.link navigate={~p"/#{Gettext.get_locale()}/about"} class={link_classes()}>
          <%= dgettext("app", "About") %>
        </.link>
        <.link navigate={~p"/#{Gettext.get_locale()}/spells"} class={link_classes()}>
          <%= dgettext("app", "Spells list") %>
        </.link>
      </nav>

      <nav class="flex items-center gap-4">
        <div class="flex gap-4 border-r pr-4">
          <.link :for={locale <- Gettext.known_locales(ForbiddenLandsWeb.Gettext)} navigate={~p"/#{locale}"}>
            <%= locale %>
          </.link>
        </div>
        <.link navigate={~p"/#{Gettext.get_locale()}/admin"} class={link_classes()}>
          <.icon name={:lock} class="w-6 h-6" />
        </.link>
      </nav>
    </header>
    """
  end

  defp link_classes(), do: "py-2 px-2 hover:bg-slate-100 rounded"
end
