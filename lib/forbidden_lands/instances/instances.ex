defmodule ForbiddenLands.Instances.Instances do
  @moduledoc false

  import Ecto.Query

  alias ForbiddenLands.Instances.Event
  alias ForbiddenLands.Instances.Instance
  alias ForbiddenLands.Repo

  @spec get(number()) :: {:ok, Instance.t()} | {:error, :not_found}
  def get(id) do
    query =
      from(
        i in Instance,
        where: i.id == ^id,
        select: i,
        preload: [events: ^from(e in Event, order_by: [desc: e.date, desc: e.id], limit: 50)]
      )

    case Repo.one(query) do
      %Instance{} = instance -> {:ok, instance}
      nil -> {:error, :not_found}
    end
  end

  @spec get_all() :: [Instance.t()]
  def get_all() do
    Repo.all(Instance)
  end

  @spec get_events(number(), list()) :: [Event.t()]
  def get_events(id, types) do
    query =
      from(
        e in Event,
        where: e.instance_id == ^id,
        where: e.type in ^types,
        order_by: [asc: e.date, asc: e.id]
      )

    Repo.all(query)
  end

  @spec create(map()) :: {:ok, Instance.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    %Instance{}
    |> Instance.create(params)
    |> Repo.insert()
  end

  @spec update(Instance.t(), map(), list()) :: {:ok, Instance.t()} | {:error, Ecto.Changeset.t()}
  def update(instance, params, resource_rules \\ [])

  def update(instance, params, resource_rules) when resource_rules == [] do
    instance
    |> Instance.update(params, instance.resource_rules)
    |> Repo.update()
  end

  def update(instance, params, resource_rules) do
    instance
    |> Instance.update(params, resource_rules)
    |> Repo.update()
  end

  @spec add_event(Instance.t(), map()) :: {:ok, Instance.t()} | {:error, Ecto.Changeset.t()}
  def add_event(instance, event) do
    instance
    |> Ecto.build_assoc(:events, event)
    |> Ecto.Changeset.cast(event.changes, [:date, :type, :title, :description])
    |> Repo.insert()
  end

  @spec update_event(map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def update_event(event) do
    Repo.update(event)
  end

  @spec remove_event(map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def remove_event(event) do
    Repo.delete(event)
  end
end
