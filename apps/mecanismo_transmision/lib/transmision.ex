defmodule MecanismoTransmision.Transmision do
    @agente_clientes :clientes
    @agente_fabrica :fabrica

    def registrar_cliente(nombre) do
        Agent.start_link(fn-> [] end, name: @agente_clientes)
        se_registro = el_cliente_se_ha_registrado(nombre)
        case se_registro do
            [_algo] -> {:ok, se_registro}
            [] -> registrar_nuevo_cliente(nombre)
        end
    end

    defp registrar_nuevo_cliente(nombre) do
        Agent.update(@agente_clientes, fn lista ->
            lista ++ [nombre]
        end)
    end

    def el_cliente_se_ha_registrado(nombre) do
        Agent.get( @agente_clientes, fn lista ->
            Enum.filter_map(lista, fn(nombre_cliente) ->
                nombre_cliente == nombre
            end, &(&1))
        end)
    end

    def registrar_fabrica(nombre) do
        se_habia_iniciado = Agent.start_link(fn -> [] end, name: @agente_fabrica)
        case se_habia_iniciado do
            {:error, _already_started} ->
                lista_registros = la_fabrica_se_ha_registrado(nombre)
                case lista_registros do
                    [_uno] -> {:ok, :registrado}
                    [] ->
                        Agent.update(@agente_fabrica, fn lista ->
                            lista ++ [nombre]
                        end)
                end
            {:ok, _pid} ->
                Agent.update(@agente_fabrica, fn lista ->
                    lista ++ [nombre]
                end)
        end
    end

    def la_fabrica_se_ha_registrado(nombre) do
        Agent.get( @agente_fabrica, fn lista ->
            Enum.filter_map(lista, fn(nombre_fabrica) ->
                nombre_fabrica == nombre
            end, &(&1))
        end)
    end

    def iniciar_nueva_transaccion_a_la_fabrica(nombre_cliente, objeto) do
        esta_conectada = verificar_que_la_fabrica_este_conectada()
        case esta_conectada do
            {:ok, _pid} -> {false, :no_se_ha_conectado}
            {:error, _already_started} -> transmitir_nueva_transaccion_a_la_fabrica(objeto, nombre_cliente)
        end
    end

    defp verificar_que_la_fabrica_este_conectada() do
        Agent.start_link(fn -> [] end, name: @agente_fabrica)
    end

    defp transmitir_nueva_transaccion_a_la_fabrica(objeto, nombre_cliente) do
        obtener_el_index_del_cliente_registrado(nombre_cliente)
        |> transmitir_transaccion_a_la_fabrica(objeto)
    end

    defp obtener_el_index_del_cliente_registrado(nombre) do
        Agent.get( @agente_clientes, fn lista ->
            Enum.find_index(lista, fn(nombre_cliente) ->
                nombre_cliente == nombre
            end)
        end)
    end

    defp transmitir_transaccion_a_la_fabrica(index_cliente, objeto) do
        MecanismoTransmision.Fabrica.nueva_transaccion(index_cliente, objeto)
        {true, :se_ha_enviado}
    end

    def iniciar_nueva_respuesta_hacia_el_cliente(index_cliente, objeto) do
        Agent.get(@agente_clientes, fn lista -> Enum.at(lista, index_cliente) end)
        |> transmitir_respuesta_hacia_el_cliente(objeto)
    end

    def transmitir_respuesta_hacia_el_cliente(nombre, objeto) do
        Agent.update(nombre, fn tupla ->
            {pid, :msgs, lista} = tupla
            send pid, objeto

            {pid, :msgs, lista ++ [objeto]}
        end)

        {true, :se_ha_respondido}
    end

    def start_link(:cliente, nombre_cliente) do
        Agent.start_link(fn -> [] end, name: @agente_clientes)
        generar_conexion_cliente(nombre_cliente)
    end

    def start_link(:fabrica, nombre_fabrica) do
        Agent.start_link(fn -> [nombre_fabrica] end, name: @agente_fabrica)
    end

    def esta_registrado(:cliente) do
        Agent.get(@agente_clientes, fn lista -> Enum.empty?(lista) end)
        |> mensaje_si_esta_registrado()
    end

    def esta_registrado(:fabrica) do
        Agent.get(@agente_fabrica, fn lista -> Enum.empty?(lista) end)
        |> mensaje_si_esta_registrado()
    end

    def transmitir_msg(pid_cliente, msg, :fabrica) do
        Agent.get(@agente_fabrica, fn lista -> Enum.at(lista, 0) end)
        |> transmitir_msg_a_fabrica(pid_cliente, msg)
    end

    def transmitir_msg(pid_cliente, msg, :cliente) do
        #Agent.get(@agente_clientes, fn lista -> Enum.at(lista, 0) end)
        transmitir_msg_a_cliente(pid_cliente, msg)
    end

    ### Internal API
    defp generar_conexion_cliente(nombre_cliente) do
        Agent.update(@agente_clientes, fn lista ->
            lista ++ [nombre_cliente]
        end)

        Agent.get(@agente_clientes, fn lista -> Enum.empty?(lista) end)
    end

    defp mensaje_si_esta_registrado(true) do
        {:ok, :noregistrado}
    end

    defp mensaje_si_esta_registrado(false) do
        {:ok, :registrado}
    end

    defp transmitir_msg_a_fabrica(nombre_fabrica, pid_cliente, msg) do
        #send :global.whereis_name(nombre_fabrica), { :nuevo_pedido, msg }
        send nombre_fabrica, { :nuevo_pedido, {pid_cliente, msg} }
    end

    defp transmitir_msg_a_cliente(pid_cliente, msg) do
        #send :global.whereis_name(nombre_fabrica), { :nuevo_pedido, msg }
        send pid_cliente, { :nueva_respuesta, msg }
    end
end
