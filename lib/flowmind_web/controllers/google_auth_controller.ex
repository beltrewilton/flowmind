defmodule FlowmindWeb.GoogleAuthController do
  use FlowmindWeb, :controller

  def redirect_to(conn, _params) do
    redirect(conn, external: google_auth_url())
  end

  defp google_auth_url do
    client_id = System.fetch_env!("GOOGLE_CALENDAR_CLIENT_ID")
    redirect_uri = URI.encode("https://flowmind.loca.lt/google_helper")
    scope = URI.encode("https://www.googleapis.com/auth/calendar.events")

    "https://accounts.google.com/o/oauth2/auth" <>
      "?client_id=#{client_id}" <>
      "&redirect_uri=#{redirect_uri}" <>
      "&response_type=code" <>
      "&scope=#{scope}" <>
      "&access_type=offline" <>
      "&prompt=consent"
  end
end
