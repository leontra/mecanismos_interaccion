defmodule MecanismoTransmision.Fabrica do
    @estado_fabrica :fabrica_agent
    @fabrica_agent :fabrica_agent

    def iniciar_conexion(pid) do
        Agent.start_link(fn -> {pid, :msgs, []} end, name: @fabrica_agent)
        MecanismoTransmision.Transmision.registrar_fabrica( @fabrica_agent )
    end

    def verificar_conexion do
        MecanismoTransmision.Transmision.la_fabrica_se_ha_registrado( @fabrica_agent )
        |> conexion_iniciada
    end

    def conexion_iniciada([_nombre_fabrica]) do
        {:ok, :conectado}
    end

    def conexion_iniciada() do
        {:error, :sin_conexion}
    end

    def obtener_transaccion_generada() do
        Agent.get(@estado_fabrica, fn tupla ->
            {_pid, :msgs, lista} = tupla
            lista
        end)
    end

    def responder_transaccion_hacia_el_cliente(index_cliente, objeto) do
        MecanismoTransmision.Transmision.iniciar_nueva_respuesta_hacia_el_cliente(index_cliente, objeto)
        |> transaccion_respondida
    end

    def transaccion_respondida({true, _msg}) do
        {:ok, :se_ha_respondido}
    end

    def transaccion_respondida({false, _msg}) do
        {:error, :no_se_respondio}
    end

    def nueva_transaccion(index_cliente, objeto) do
        Agent.update(@fabrica_agent, fn tupla ->
            {pid, :msgs, lista} = tupla
            send pid, objeto

            {pid, :msgs, lista ++ [{index_cliente, objeto}]}
        end)
    end

    #def estado(pid) do
    #    Agent.get(@estado_fabrica, fn lista ->
    #        lista
    #    end)
    #    #|> estado_msg(pid)
    #end

    #defp estado_msg(msgs, pid) do
    #    send(pid, {:ok, :estado, msgs})
    #end

    #def receiver do
    #    receive do
    #        { :nuevo_pedido, pid, msg } ->
    #            procesar_pedido(msg)
    #            #estado(pid)

    #        { :pedidos, pid } ->
    #            estado(pid)

    #        { :numero, pid } ->
    #            send(pid, 121)
    #    end
    #end

end

defmodule MecanismoTransmision.Fabriqa do
    def start do
        await([])
    end

    def await(msgs) do
        receive do
            { :nuevo_pedido, msg } -> msgs = nuevo_mensaje_recibido(msg, msgs)
            { :pedidos, pid } -> divulge_balance(pid, msgs)
        end

        await(msgs)
    end

    def divulge_balance(pid, msgs) do
        send(pid, {:recibidos, msgs})
    end

    def nuevo_mensaje_recibido(msg, msgs) do
        msgs ++ [msg]
    end
end
