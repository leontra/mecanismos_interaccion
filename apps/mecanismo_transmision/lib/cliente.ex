defmodule MecanismoTransmision.Cliente do

    def iniciar_conexion(nombre, pid) do
        Agent.start_link(fn -> {pid, :msgs, []} end, name: nombre)
        MecanismoTransmision.Transmision.registrar_cliente(nombre)
    end

    def verificar_conexion(nombre) do
        MecanismoTransmision.Transmision.el_cliente_se_ha_registrado(nombre)
        |> conexion_iniciada
    end

    def conexion_iniciada([_nombre_cliente]) do
        {:ok, :conectado}
    end

    def conexion_iniciada() do
        {:error, :sin_conexion}
    end

    def iniciar_transaccion_con_fabrica(nombre, objeto) do
        MecanismoTransmision.Transmision.iniciar_nueva_transaccion_a_la_fabrica(nombre, objeto)
        |> transaccion_iniciada
    end

    def transaccion_iniciada({true, _msg}) do
        {:ok, :se_ha_enviado}
    end

    def transaccion_iniciada({false, _msg}) do
        {:error, :no_se_inicio}
    end

    def obtener_transaccion_respuesta(nombre) do
        Agent.get(nombre, fn tupla ->
            {_pid, :msgs, lista} = tupla
            lista
        end)
    end

end
