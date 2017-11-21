defmodule Mws.Parser do
  require Logger

  @moduledoc """
  This module handles response data from the API, parses it where possible and
  returns a formatted result.
  """

  def handle_response({:ok, %{body: body, headers: headers, status_code: _code}}) do
    body =
      case get_content_type(headers) do
        "text/xml"                        -> XmlToMap.naive_map(body)
        "text/xml;charset=" <> _charset   -> XmlToMap.naive_map(body)
        "text/plain;charset=" <> _charset ->
          body
          |> String.split("\r\n")
          |> CSV.decode(seperator: ?\t, headers: true)
        _ -> body
      end

    # Turn the headers into a map
    headers =
      headers
      |> Enum.reduce(%{}, fn({k, v}, acc) ->
        Map.put(acc, k, v)
      end)

    %{headers: headers, body: body}
  end

  def handle_response({:error, err}) do
    Logger.error "HTTP Request resulted in an error"
    {:error, err}
  end

  def get_content_type(headers) do
    Enum.find_value headers, fn
      {"Content-Type", value} -> value
      _ -> false
    end
  end
end
