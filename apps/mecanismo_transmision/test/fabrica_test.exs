defmodule MecanismoTransmision.FabricaTest do
  use ExUnit.Case, async: true

  @doctest """
    Estas pruebas estan hechas para probar una fabrica del modo mas sencillo y primitivo
    que se pueda, es un mecanismo donde la fabrica todo el tiempo esta esperando
  """

  test "conectar una sola fabrica" do
      MecanismoTransmision.Fabrica.iniciar_conexion(self)
      assert {:ok, :conectado} = MecanismoTransmision.Fabrica.verificar_conexion()
  end

  test "conectar fabrica por primera vez y volver a conectarlo, ver que no se duplique" do
      MecanismoTransmision.Fabrica.iniciar_conexion(self)
      assert {:ok, :conectado} = MecanismoTransmision.Fabrica.verificar_conexion()

      MecanismoTransmision.Fabrica.iniciar_conexion(self)
      assert {:ok, :conectado} = MecanismoTransmision.Fabrica.verificar_conexion()
  end

  test "iniciar una nueva transaccion por parte del cliente y generar una respuesta" do
      MecanismoTransmision.Fabrica.iniciar_conexion(self)

      MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
      MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})

      assert [{_cliente, {:vertices, x: 121, y: 125}}] = MecanismoTransmision.Fabrica.obtener_transaccion_generada()
  end

  test "responder por parte de la fabrica a una transaccion iniciada por un cliente" do
      MecanismoTransmision.Fabrica.iniciar_conexion(self)

      MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
      MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})

      [{index_cliente, {:vertices, x: x, y: y}}] = MecanismoTransmision.Fabrica.obtener_transaccion_generada()
      assert {:ok, :se_ha_respondido} = MecanismoTransmision.Fabrica.responder_transaccion_hacia_el_cliente(index_cliente, {:vertices, x: x + 10, y: y + 10})
  end

  test "responder por parte de la fabrica a una transaccion iniciada por dos clientes diferentes" do
      MecanismoTransmision.Fabrica.iniciar_conexion(self)

      MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
      MecanismoTransmision.Cliente.iniciar_conexion(:cliente_dos, self)

      MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})
      [{index_cliente, {:vertices, x: x, y: y}}] = MecanismoTransmision.Fabrica.obtener_transaccion_generada()
      assert {:ok, :se_ha_respondido} = MecanismoTransmision.Fabrica.responder_transaccion_hacia_el_cliente(index_cliente, {:vertices, x: x + 10, y: y + 10})

      MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_dos, {:vertices, x: 10, y: 10})
      [_cliente_uno, {index_cliente_dos, {:vertices, x: x_dos, y: y_dos}}] = MecanismoTransmision.Fabrica.obtener_transaccion_generada()
      assert {:ok, :se_ha_respondido} = MecanismoTransmision.Fabrica.responder_transaccion_hacia_el_cliente(index_cliente_dos, {:vertices, x: x_dos + 10, y: y_dos + 10})
  end

  test "iniciar nueva transaccion por parte del cliente para transmitirlo hacia la fabrica y hacia un proceso extero" do
      MecanismoTransmision.Fabrica.iniciar_conexion(self)

      MecanismoTransmision.Cliente.iniciar_conexion(:cliente_uno, self)
      MecanismoTransmision.Cliente.iniciar_transaccion_con_fabrica(:cliente_uno, {:vertices, x: 121, y: 125})

      assert_receive {:vertices, x: 121, y: 125}
  end

  #test "probar fabriqa" do
      #fabriqa = spawn_link(MecanismoTransmision.Fabriqa, :start, [])
      #send(fabriqa, { :pedidos, self })
      #assert_receive { :recibidos, [] }
  #end

  #test "probar mensaje enviado hacia fabrica" do
      #fabriqa = spawn_link(MecanismoTransmision.Fabriqa, :start, [])
      #send(fabriqa, { :nuevo_pedido, "hola cara de bola" })
      #send(fabriqa, { :pedidos, self })
      #assert_receive { :recibidos, ["hola cara de bola"] }
  #end

  #test "probar dos mensajes enviados hacia la fabrica" do
      #fabriqa = spawn_link(MecanismoTransmision.Fabriqa, :start, [])
      #send(fabriqa, { :nuevo_pedido, "hola cara de torta" })
      #send(fabriqa, { :nuevo_pedido, "hola cara de bola" })

      #send(fabriqa, { :pedidos, self })
      #assert_receive { :recibidos, ["hola cara de torta", "hola cara de bola"] }
  #end

  @doctest """
    Estas pruebas estan hechas para probar una fabrica con un mecanismo de tasks y agents,
    es una alternativa a gen_server pero sin caer tampoco en algo de tan bajo nivel
  """

  ##test "iniciar conexion por parte de una sola fabrica" do
      #assert {:ok, _pid} = MecanismoTransmision.Fabrica.start()
  ##end

  #test "probar que los mensajes de la fabrica esten vacios al inicio" do
      #fabrica = Task.async( MecanismoTransmision.Fabrica.start() )
      #MecanismoTransmision.Fabrica.start()
      #MecanismoTransmision.Fabrica.procesar_pedido("hola")

      #assert ["hola"] = MecanismoTransmision.Fabrica.estado(self)
      #assert_receive { :ok, :estado, []}
  #end

  #test "transmitir un msg hacia la fabrica y comprobar que lo haya recibido" do
      #MecanismoTransmision.Fabrica.start()
      #MecanismoTransmision.Fabrica.procesar_pedido("hola")
      #MecanismoTransmision.Fabrica.procesar_pedido("cara")

      #assert ["hola", "cara"] = MecanismoTransmision.Fabrica.estado(self)
  #end

  #test "transmitir dos msgs hacia la fabrica y comprobar que los haya recibido" do
      #{ :ok, fabrica } = MecanismoTransmision.Fabrica.start()

      #send(fabrica, { :nuevo_pedido, self, "hola cara de torta" })
      #send(fabrica, { :nuevo_pedido, self, "de" })
      #send(fabrica, { :nuevo_pedido, self, "bola" })

      #MecanismoTransmision.Fabrica.procesar_pedido("hola")
      #MecanismoTransmision.Fabrica.procesar_pedido("cara")

      #send(fabrica, { :pedidos, self })
      #assert_receive { :ok, :estado, ["hola cara de"] }

      #worker = Task.async(fn ->
    #      send(fabrica, { :nuevo_pedido, self, "de" })
    #      #send(fabrica, { :nuevo_pedido, self, "bola" })
    #      send(fabrica, { :pedidos, self })
    #      assert_receive 121
      #end)

      #Task.await(worker)
      ##IO.puts "The result is #{result}"
      #assert result = {:oksds, :estado, ["ss"]}
      #assert_receive {:ok, :estado, ["ss"]}
      #ref  = Process.monitor(worker.pid)
      #assert_receive {:DOWn, ^ref, :process, _, :normal}, 1500
  #end

end
