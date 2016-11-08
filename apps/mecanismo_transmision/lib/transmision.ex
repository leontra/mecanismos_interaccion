defmodule MecanismoTransmision.Transmision do
    @agente_clientes :clientes
    @agente_fabrica :fabrica

    def start_link(:cliente, nombre_cliente) do
        Agent.start_link(fn -> [] end, name: @agente_clientes)
        Agent.get(@agente_clientes, fn lista -> Enum.empty?(lista) end)
        |> generar_conexion_cliente(nombre_cliente)
        |> con_clientes_en_lista_vacia()
    end

    def start_link(:fabrica, pid) do
        Agent.start_link(fn -> [pid] end, name: @agente_fabrica)
    end

    def transmitir_msg(:cliente, msg, :fabrica) do
        Agent.get(@agente_fabrica, fn lista -> Enum.at(lista, 0) end)
        |> transmitir_msg_a_fabrica(msg)
        |> status_transmision()
    end

    ### Internal API
    defp generar_conexion_cliente(true, nombre_cliente) do
        Agent.update(@agente_clientes, fn lista ->
            lista ++ [nombre_cliente]
        end)

        Agent.get(@agente_clientes, fn lista -> Enum.empty?(lista) end)
    end

    defp con_clientes_en_lista_vacia(false) do
        {:ok, true}
    end

    defp con_clientes_en_lista_vacia(true) do
        {:ok, false}
    end

    defp transmitir_msg_a_fabrica(pid_fabrica, msg) do
        send(pid_fabrica, {:incoming, msg })
        :ok
    end

    defp status_transmision(:ok) do
        {:ok, :mensaje_transmitido}
    end
end
