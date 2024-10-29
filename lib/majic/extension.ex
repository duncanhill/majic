defmodule Majic.Extension do
  @moduledoc """
  Helper module to fix extensions. Uses [MIME](https://hexdocs.pm/mime/MIME.html).
  """

  @typedoc """
  If an extension is defined for a given MIME type, append it to the previous extension.

  If no extension could be found for the MIME type, and `subtype_as_extension: false`, the returned filename will have no extension.
  """
  @type option_append :: {:append, false | true}

  @typedoc "If no extension is defined for a given MIME type, use the subtype as its extension."
  @type option_subtype_as_extension :: {:subtype_as_extension, false | true}

  @spec fix(Path.t(), Majic.Result.t() | String.t(), [
          option_append() | option_subtype_as_extension()
        ]) :: Path.t()
  @doc """
  Fix `name`'s extension according to `result_or_mime_type`.

  ```elixir
  iex(1)> {:ok, result} = Majic.perform("cat.jpeg", once: true)
  {:ok, %Majic.Result{mime_type: "image/webp", ...}}
  iex(1)> Majic.Extension.fix("cat.jpeg", result)
  "cat.webp"
  ```

  The `append: true` option will append the correct extension to the user-provided one, if there's an extension for the
  type:

  ```
  iex(1)> Majic.Extension.fix("cat.jpeg", result, append: true)
  "cat.jpeg.webp"
  iex(2)> Majic.Extension.fix("Makefile.txt", "text/x-makefile", append: true)
  "Makefile"
  ```

  The `subtype_as_extension: true` option will use the subtype part of the MIME type as an extension for the ones that
  don't have any:

  ```elixir
  iex(1)> Majic.Extension.fix("Makefile.txt", "text/x-makefile", subtype_as_extension: true)
  "Makefile.x-makefile"
  iex(1)> Majic.Extension.fix("Makefile.txt", "text/x-makefile", subtype_as_extension: true, append: true)
  "Makefile.txt.x-makefile"
  ```
  """
  def fix(name, result_or_mime_type, options \\ [])

  def fix(name, %Majic.Result{mime_type: mime_type}, options) do
    do_fix(name, mime_type, options)
  end

  def fix(name, mime_type, options) do
    do_fix(name, mime_type, options)
  end

  defp do_fix(name, mime_type, options) do
    append? = Keyword.get(options, :append, false)
    subtype? = Keyword.get(options, :subtype_as_extension, false)
    ext_candidates = MIME.extensions(mime_type)
    old_ext = String.downcase(Path.extname(name))
    old_ext_bare = String.trim_leading(old_ext, ".")
    basename = Path.basename(name, old_ext)

    cond do
      # extension already in candidate list, so no-op
      old_ext_bare in ext_candidates ->
        name

      # has extension, append the subtype
      not match?("", old_ext) && append? && subtype? ->
        Enum.join([name, subtype_extension(subtype?, mime_type)], ".")

      # has extension, change to subtype
      not match?("", old_ext) && subtype? ->
        Enum.join([basename, subtype_extension(subtype?, mime_type)], ".")

      # no extension, append 
      match?("", old_ext) && append? ->
        Enum.join([basename, List.first(ext_candidates)], ".")

      # no candidates, so strip extension
      match?([], ext_candidates) ->
        basename

      # no extension but no appending, so no-op
      match?("", old_ext) ->
        name

      # append first candidate
      not Enum.empty?(ext_candidates) && append? ->
        Enum.join([name, List.first(ext_candidates)], ".")

      # change extension to first candidate
      not Enum.empty?(ext_candidates) ->
        Enum.join([basename, List.first(ext_candidates)], ".")

      # do nothing
      true ->
        name
    end
  end

  defp subtype_extension(true, type) do
    [_type, sub] = String.split(type, "/", parts: 2)
    [sub]
  end

  defp subtype_extension(_, _), do: []
end
