defmodule RetWeb.Middleware do
  @moduledoc "Adds absinthe middleware on matching fields/objects"

  alias RetWeb.Middleware.{LogMiddleware, VerifyToken, VerifyScopes, HandleChangesetErrors, StartTiming, EndTiming, InspectTiming}

  def build_middleware(middleware, field, object) do
    # TODO: Order matters here, and is precarious. Should insert or not insert middleware in a known order as a result of the matches
    middleware = maybe_add_handle_changeset_errors(middleware, field, object)
    middleware = maybe_add_verify_scopes(middleware, field, object)
    middleware = maybe_add_verify_token(middleware, field, object)
    middleware = maybe_add_timing(middleware, field, object)
    middleware
  end

  # TODO: What is the best way to make sure that fields _have_ to be authed, and there's no way to get around this check
  # This is incomplete : should check each resource individually. E.g. "Show me five rooms" but we return 3 of them and 2 are auth errors.
  # TODO: Auth on room objects (and other resources)
  @auth_fields [
    :my_rooms,
    :public_rooms,
    :favorite_rooms,
    :create_room,
    :update_room
  ]

  defp maybe_add_verify_token(middleware, %{identifier: identifier}, _object) when identifier in @auth_fields do
    [VerifyToken] ++ middleware
  end

  defp maybe_add_verify_token(middleware, _field, _object) do
    middleware
  end

  @auth_objects [
    :room
  ]

  defp maybe_add_verify_scopes(middleware, _field, %{identifier: identifier}) when identifier in @auth_objects do
    [LogMiddleware] ++ middleware
  end

  defp maybe_add_verify_scopes(middleware, %{identifier: identifier}, _object) when identifier in @auth_fields do
    [VerifyScopes] ++ middleware
  end

  defp maybe_add_verify_scopes(middleware, _field, _object) do
    middleware
  end

  defp maybe_add_handle_changeset_errors(middleware, _field, %{identifier: :mutation}) do
    middleware ++ [HandleChangesetErrors]
  end

  defp maybe_add_handle_changeset_errors(middleware, _field, _object) do
    middleware
  end

  @timing_ids [
    :my_rooms,
    :public_rooms,
    :favorite_rooms,
    :create_room,
    :update_room
  ]

  defp maybe_add_timing(middleware, %{identifier: identifier}, _object) when identifier in @timing_ids do
    [StartTiming] ++ middleware ++ [EndTiming, InspectTiming]
  end

  defp maybe_add_timing(middleware, _field, _object) do
    middleware
  end
end
