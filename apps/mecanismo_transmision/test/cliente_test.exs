defmodule MecanismoTransmision.ClienteTest do
    use ExUnit.Case, async: true

    test "conectar un solo cliente" do
        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
        assert {:ok, :conectado} = MecanismoTransmision.Cliente.verificar_conexion(:cliente_uno)
    end

    test "conectar cliente por primera vez y volver a conectarlo, ver que no se repita" do
        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
        assert {:ok, :conectado} = MecanismoTransmision.Cliente.verificar_conexion(:cliente_uno)

        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
        assert {:ok, :conectado} = MecanismoTransmision.Cliente.verificar_conexion(:cliente_uno)
    end

    test "conectar dos clientes diferentes" do
        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_dos, self)

        assert {:ok, :conectado} = MecanismoTransmision.Cliente.verificar_conexion(:cliente_uno)
        assert {:ok, :conectado} = MecanismoTransmision.Cliente.verificar_conexion(:cliente_dos)
    end

    test "iniciar transaccion por parte de un cliente y esperar que no se haga porque la fabrica no ha iniciado conexion" do
        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
        assert {:error, :no_se_inicio} = MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})
    end

    test "iniciar transaccion por parte de un cliente antes de que se conecte la fabrica y despues de que lo haga" do
        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
        assert {:error, :no_se_inicio} = MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})

        MecanismoTransmision.Fabrica.iniciar_conexion(self)
        assert {:ok, :se_ha_enviado} = MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})
    end

    test "iniciar transaccion por parte del cliente y verificar que se haya mandado" do
        MecanismoTransmision.Fabrica.iniciar_conexion(self)
        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
        assert {:ok, :se_ha_enviado} = MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})
    end

    test "iniciar transaccion por parte del cliente y verificar que la fabrica haya respondido" do
        MecanismoTransmision.Fabrica.iniciar_conexion(self)

        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
        MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})

        [{index_cliente, {:vertices, x: x, y: y}}] = MecanismoTransmision.Fabrica.obtener_transaccion_generada()
        MecanismoTransmision.Fabrica.responder_transaccion_hacia_el_cliente(index_cliente, {:vertices, x: x + 10, y: y + 10})

        assert [{:vertices, x: 131, y: 135}] = MecanismoTransmision.Cliente.obtener_transaccion_respuesta(:cliente_uno)
    end

    test "iniciar transaccion dos veces por un cliente y verificar que se hayan mandado" do
        MecanismoTransmision.Fabrica.iniciar_conexion(self)
        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)

        assert {:ok, :se_ha_enviado} = MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})
        assert {:ok, :se_ha_enviado} = MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 10, y: 20})
    end

    test "iniciar transaccion por parte de dos clientes diferentes y verificar que se hayan mandado" do
        MecanismoTransmision.Fabrica.iniciar_conexion(self)
        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_dos, self)

        assert {:ok, :se_ha_enviado} = MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})
        assert {:ok, :se_ha_enviado} = MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_dos, {:vertices, x: 10, y: 20})
    end

    test "iniciar transaccion por parte de dos clientes diferentes y verificar que la fabrica haya respondido" do
        MecanismoTransmision.Fabrica.iniciar_conexion(self)

        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_dos, self)

        MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})

        [{index_cliente, {:vertices, x: x, y: y}}] = MecanismoTransmision.Fabrica.obtener_transaccion_generada()
        MecanismoTransmision.Fabrica.responder_transaccion_hacia_el_cliente(index_cliente, {:vertices, x: x + 10, y: y + 10})

        assert [{:vertices, x: 131, y: 135}] = MecanismoTransmision.Cliente.obtener_transaccion_respuesta(:cliente_uno)


        MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_dos, {:vertices, x: 10, y: 10})

        [_cliente_uno, {index_cliente_dos, {:vertices, x: x_dos, y: y_dos}}] = MecanismoTransmision.Fabrica.obtener_transaccion_generada()
        MecanismoTransmision.Fabrica.responder_transaccion_hacia_el_cliente(index_cliente_dos, {:vertices, x: x_dos + 10, y: y_dos + 10})

        assert [{:vertices, x: 20, y: 20}] = MecanismoTransmision.Cliente.obtener_transaccion_respuesta(:cliente_dos)
    end

    test "probar transmision de mensajes recibidos hacia un proceso externo" do
        MecanismoTransmision.Fabrica.iniciar_conexion(self)

        MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)

        MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})

        [{index_cliente, {:vertices, x: x, y: y}}] = MecanismoTransmision.Fabrica.obtener_transaccion_generada()
        MecanismoTransmision.Fabrica.responder_transaccion_hacia_el_cliente(index_cliente, {:vertices, x: x + 10, y: y + 10})

        assert_receive {:vertices, x: 131, y: 135}
    end

end
