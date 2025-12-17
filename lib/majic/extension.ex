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
    has_old_ext? = old_ext != ""

    cond do
      old_ext_bare in ext_candidates ->
        name

      has_old_ext? ->
        fix_with_extension(name, basename, ext_candidates, append?, subtype?, mime_type)

      true ->
        fix_without_extension(name, basename, ext_candidates, append?)
    end
  end

  defp fix_with_extension(name, basename, ext_candidates, append?, subtype?, mime_type) do
    new_ext = get_new_extension(ext_candidates, subtype?, mime_type)

    cond do
      new_ext != nil && append? -> join_extension(name, new_ext)
      new_ext != nil -> join_extension(basename, new_ext)
      true -> basename
    end
  end

  defp fix_without_extension(name, basename, ext_candidates, append?) do
    case List.first(ext_candidates) do
      nil -> name
      ext when append? -> join_extension(basename, ext)
      _ext -> name
    end
  end

  defp get_new_extension(ext_candidates, subtype?, mime_type) do
    case {List.first(ext_candidates), subtype?} do
      {nil, true} -> subtype_from_mime(mime_type)
      {nil, false} -> nil
      {ext, _} -> ext
    end
  end

  defp subtype_from_mime(mime_type) do
    [_type, sub] = String.split(mime_type, "/", parts: 2)
    sub
  end

  defp join_extension(base, ext), do: Enum.join([base, ext], ".")
end
