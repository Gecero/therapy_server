defmodule TherapyServer do
  require Logger

  def start_link(port) do
    Task.start_link(fn -> listen(port) end)
  end

  def child_spec(arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  defp listen(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Server up, listening on port #{port}")
    Logger.info("Connect using: netcat localhost #{port} (if you are using OpenBSD netcat)")
    accept(socket)
  end

  defp accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Task.start(fn -> welcome(client) end)
    accept(socket)
  end

  defp welcome(client) do
    :gen_tcp.send(client, """
    Willkommen bei Dr. Huso!
    Aufgrund meiner multiplen Persönlichkeiten kannst du auswählen:
    (1) TPG-0 (ArschGPT)               (2) TPG-1 (DocGPT)
    (3) TPG-2 (PhilosophenGPT)
    """)
    {:ok, data} = :gen_tcp.recv(client, 0)
    case Integer.parse(data) do
      {1, _} -> 
        :gen_tcp.send(client, "Dr. Huso: Nerv nich!\n      Du: ")
        loop(client, &tpg0/1)
      {2, _} -> 
        :gen_tcp.send(client, "Dr. Huso: Erzähl mir von all dem bösen in dir.\n      Du: ")
        loop(client, &tpg1/1)
      {3, _} -> 
        :gen_tcp.send(client, "Dr. Huso: Die Weisheit steckt in uns, wir müssen sie nur finden.\n      Du: ")
        loop(client, &tpgphilo/1)
      _ ->
        :gen_tcp.send(client, "Fehler: ungültige Eingabe!\n")
        :gen_tcp.close(client)
    end
  end

  # TPG-0 will just mock you
  defp tpg0(data) do
    data
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map(fn {char, index} ->
      if rem(index, 2) == 0 do
        String.upcase(char)
      else
        char
      end
    end)
    |> Enum.join()
  end

  
  defp switch_personal_pronouns(response) do
    String.replace(response, "du", "i1ch")
    |> String.replace("nich", "ni2ch") # We don't want to replace it, but keep it
    |> String.replace("mich", "di2ch")
    |> String.replace("dich", "mi2ch")
    |> String.replace("ich", "d1u")
    |> String.replace("dein", "m1ein")
    |> String.replace("deine", "m1eine")
    |> String.replace("deiner", "m1einer")
    |> String.replace("mein", "d1ein")
    |> String.replace("meine", "d1eine")
    |> String.replace("meiner", "d1einer")
    |> String.replace("unser", "e1uer")
    |> String.replace("unsere", "e1ure")
    |> String.replace("euer", "u1nser")
    |> String.replace("eure", "u1nsere")
    |> String.replace("mir", "d1ir")
    |> String.replace("dir", "m1ir")
    
    # Wir benötigen den zweischrittigen Ansatz, um zu verhindern
    # dass z.B. ein "mein" zu "dein" wird und danach wieder zu "mein",
    # weil nach den mein's alle dein's getauscht werden
    |> String.replace("i1ch", "ich")
    |> String.replace("d1u", "du")
    |> String.replace("m1ein", "mein")
    |> String.replace("m1eine", "meine")
    |> String.replace("m1einer", "meiner")
    |> String.replace("d1ein", "dein")
    |> String.replace("d1eine", "deine")
    |> String.replace("d1einer", "deiner")
    |> String.replace("e1uer", "euer")
    |> String.replace("e1ure", "eure")
    |> String.replace("u1nser", "unser")
    |> String.replace("u1nsere", "unsere")
    |> String.replace("m1ir", "mir")
    |> String.replace("d1ir", "dir")
    |> String.replace("di2ch", "dich")
    |> String.replace("mi2ch", "mich")
    |> String.replace("ni2ch", "nich")
  end

  def remove_sentence_endings(str) do
    str
    |> String.replace(~r/[.!?](\s|$)/, "\\1")
  end

  defp tpg1(input) do
    # So when we match against multiple regexes and want to repeat stuff the 
    # user says, we specify '(.*)'. But if we add an OR statement using '|',
    # the function doesn't return a list sorta tuple of {full_match, match_of_(.*)}, 
    # but a tuple of all matches specified, including the empty matches
    # (or rather non-matches). Therefore we use this function to filter out 
    # the match of (.*) that is not empty
    extract = fn captures -> Enum.find(tl(captures), &(&1 != "")) end

    patterns = [
      {~r/brauche (.*)|benötige (.*)/i, fn need -> "Warum brauchen Sie #{extract.(need)}?" end},
      {~r/mutter|mama|mom|mum/i, fn _ -> "Erzählen Sie mir mehr über Ihre Mutter." end},
      {~r/vater|papa|dad/i, fn _ -> "Erzählen Sie mir mehr über Ihren Vater." end},
      {~r/möchte (.*)|will (.*)/i, fn desire -> "Warum möchten Sie #{extract.(desire)}?" end},
      {~r/bin (.*)|fühle (.*)/i, fn state -> "Wie lange sind Sie schon #{extract.(state)}?" end},
      {~r/hilfe|problem|sucht|angst|möchte nicht|will nicht|mag nicht/i, fn _ -> tpg0(input) end},
      {~r/schmerz|weh|mobb|aua/i, fn _ -> "Ich habe da ein tolles, neues Medikament." end},
      {~r/fick dich|fuck you|huso|maul|klappe|hure|bastard|arsch|sack|mistkerl|bist scheiße|stinkst|miefst|spacko|spasti|schwuchtel/i, fn _ -> "Fick dich! Du bist der schlechteste Patient, den ich je hatte!" end},
      {~r/kannst|könntest|willst|möchtest|würdest|wirst/i, fn _ -> "Ich bin nicht dein Butler!" end},
      {~r/böse|mord|missbrauch|belästigung|hitler|nazi|gewalt|schlag/i, fn _ -> "Denk positiv, bitch!" end},
    ]

    case Enum.find(patterns, fn {regex, _} -> Regex.match?(regex, input) end) do
      {regex, func} ->
        captures = Regex.run(regex, input)
        |> Enum.map(&switch_personal_pronouns/1)
        func.(captures)

      nil -> Enum.random([
        "Erzählen Sie mir mehr.",
        "Ach!",
        "Is nich wahr!",
        "Uiuiui!",
        "Caramba!",
        ])
    end
  end

  defp tpgphilo(input) do
    "#{switch_personal_pronouns(input)}?"
  end

  defp loop(client, func) do
    case :gen_tcp.recv(client, 0) do
      {:ok, data} ->
        data
        |> String.downcase() # Some input detection only works with lowercase
        |> remove_sentence_endings()
        |> func.()
        |> String.replace("\r", "")
        |> String.replace("\n", "")
        |> (fn msg -> :gen_tcp.send(client, "Dr. Huso: #{msg}\n      Du: ") end).()
        loop(client, func)
      {:error, _reason} ->
        :gen_tcp.close(client)
    end
  end
end

