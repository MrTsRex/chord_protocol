defmodule RandomString do
    def randstr, do: randstr_([])
       
    defp randstr_(list) when length(list)<15 do
        char = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
                |> String.codepoints
                |> Enum.take_random(1)
                |> List.first
        randstr_([char|list])
    end
    defp randstr_(list) when length(list)>=15 , do: Enum.join(list)
end