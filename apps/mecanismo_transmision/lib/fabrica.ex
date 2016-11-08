defmodule MecanismoTransmision.Fabrica do
    def start do
        Agent.start_link(fn -> [] end, name: :fabrica_agent)
        pid = spawn(__MODULE__, :receiver, [])
        MecanismoTransmision.Transmision.start_link(:fabrica, pid)
        {:ok, pid}
        #pid
    end

    def estado(pid_fabrica) do
        Agent.get(:fabrica_agent, fn lista ->
            lista
        end)
        |> estado_msg()
    end

    def receiver do
        receive do
            { :incoming, msg } ->
                Agent.update(:fabrica_agent, fn lista ->
                    lista ++ [msg]
                end)
        end
    end

    defp estado_msg(msg) do
        {:ok, :incoming, msg}
    end
end
