defmodule FabricaPrueba do

    @nombre_fabrica_prueba :fabrica_prueba

    def start do
        spawn(__MODULE__, :receiver, [[]])
        #:global.register_name(@nombre_fabrica_prueba, pid)
    end

    def receiver(msgs) do
        receive do
            { :nuevo_pedido, {pid_cliente, msg} } ->
                #IO.puts "Nuevo pedido #{msg}"
                receiver([{pid_cliente, msg}|msgs])

            { :pedidos, pid } ->
                send(pid, { :estado, msgs })
                receiver(msgs)
        end
    end
end

defmodule ClientePrueba do

    @nombre_fabrica_prueba :cliente_prueba

    def start do
        spawn(__MODULE__, :receiver, [[]])
        #:global.register_name(@nombre_fabrica_prueba, pid)
    end

    def receiver(msgs) do
        receive do
            { :nueva_respuesta, msg } ->
                #IO.puts "Nueva respuesta #{msg}"
                receiver([msg|msgs])

            { :respuestas, pid } ->
                send(pid, { :estado, msgs })
                receiver(msgs)
        end
    end
end

defmodule MecanismoTransmision.TransmisionTest do
  use ExUnit.Case, async: true

  @doctest """
    Estos primeros tests están hechos para la
    interacción entre un solo cliente y una sola fábrica
  """
  #test "iniciar conexion por parte de un solo cliente y revisar que lo haya registrado" do
      #MecanismoTransmision.Transmision.start_link(:cliente, :cliente_uno)
      #assert {:ok, :registrado} = MecanismoTransmision.Transmision.esta_registrado(:cliente)
  #end

  test "iniciar conexion por parte de la fabrica y revisar que se haya registrado" do
      MecanismoTransmision.Transmision.start_link(:fabrica, FabricaPrueba.start())
      assert {:ok, :registrado} = MecanismoTransmision.Transmision.esta_registrado(:fabrica)
  end

  test "transmitir mensaje hacia la fabrica por parte de un cliente" do
      pid = FabricaPrueba.start()
      MecanismoTransmision.Transmision.start_link(:cliente, :cliente_uno)
      MecanismoTransmision.Transmision.start_link(:fabrica, pid)

      MecanismoTransmision.Transmision.transmitir_msg(:cliente_uno, "hola", :fabrica)

      send pid, { :pedidos, self }
      assert_receive { :estado, [{:cliente_uno, "hola"}] }
  end

  test "responder a un mensaje del cliente por parte de la fabrica" do
      pid_fabrica = FabricaPrueba.start()
      pid_cliente = ClientePrueba.start()

      MecanismoTransmision.Transmision.start_link(:cliente, pid_cliente)
      MecanismoTransmision.Transmision.start_link(:fabrica, pid_fabrica)

      MecanismoTransmision.Transmision.transmitir_msg(pid_cliente, "hola", :fabrica)
      send pid_fabrica, { :pedidos, self }
      assert_receive { :estado, [{pid_cliente, "hola"}]}
      #:erlang.process_info(self, :messages) |> IO.inspect

      MecanismoTransmision.Transmision.transmitir_msg(pid_cliente, "hola mundo", :cliente)
      send pid_cliente, { :respuestas, self }
      assert_receive { :estado, ["hola mundo"] }
  end



  #test "iniciar conexion por parte de una sola fabrica" do
      #assert {:ok, _pid} = MecanismoTransmision.Fabrica.start()
  #end#

  #test "transmitir un msg del cliente hacia la fabrica" do
      #MecanismoTransmision.Transmision.start_link(:cliente, :cliente_uno)
      #MecanismoTransmision.Fabrica.start()

      #assert {:ok, :mensaje_transmitido} = MecanismoTransmision.Transmision.transmitir_msg(:cliente, "Hola cara de bola", :fabrica)
  #end#

  #test "transmitir un msg del cliente hacia la fabrica y la fabrica lo recibe" do
      #MecanismoTransmision.Transmision.start_link(:cliente, :cliente_uno)
      #{:ok, pid_fabrica} = MecanismoTransmision.Fabrica.start()
      #MecanismoTransmision.Transmision.transmitir_msg(:cliente, "Hola cara de torta", :fabrica)

      #assert {:ok, :estado} = send(pid_fabrica, { :estado, 10 })
      #assert {:ok, :incoming, "Hola cara de torta"} = MecanismoTransmision.Fabrica.estado()
      #task = Task.async(fn -> :algo end)
      #ref  = Process.monitor(task.pid)
      #assert_receive {:DOWN, ^ref, :process, _, :normal}, 1500
  #end

  @doctest """
  Estos otros tests son para iniciar la conexión hacia el mecanismo de Transmision
  de un o varios clientes
  """

  test "iniciar conexion por parte de dos clientes al mismo transmisor" do
      pid_cliente_uno = ClientePrueba.start()
      pid_cliente_dos = ClientePrueba.start()

      MecanismoTransmision.Transmision.start_link(:cliente, pid_cliente_uno)
      MecanismoTransmision.Transmision.start_link(:cliente, pid_cliente_dos)

      assert {:ok, :registrado} = MecanismoTransmision.Transmision.esta_registrado(:cliente)

      pid_fabrica = FabricaPrueba.start()

      MecanismoTransmision.Transmision.start_link(:fabrica, pid_fabrica)

      MecanismoTransmision.Transmision.transmitir_msg(pid_cliente_uno, "hola", :fabrica)
      MecanismoTransmision.Transmision.transmitir_msg(pid_cliente_dos, "cara", :fabrica)

      send pid_fabrica, { :pedidos, self }
      assert_receive { :estado, [{pid_cliente_uno, "cara"}, {pid_cliente_dos, "hola"}] }
  end

  test "responder a un mensaje de dos clientes por parte de la fabrica" do
      pid_cliente_uno = ClientePrueba.start()
      pid_cliente_dos = ClientePrueba.start()

      MecanismoTransmision.Transmision.start_link(:cliente, pid_cliente_uno)
      MecanismoTransmision.Transmision.start_link(:cliente, pid_cliente_dos)

      pid_fabrica = FabricaPrueba.start()
      MecanismoTransmision.Transmision.start_link(:fabrica, pid_fabrica)

      MecanismoTransmision.Transmision.transmitir_msg(pid_cliente_uno, "hola", :fabrica)
      MecanismoTransmision.Transmision.transmitir_msg(pid_cliente_dos, "cara", :fabrica)

      send pid_fabrica, { :pedidos, self }
      assert_receive { :estado, [{pid_cliente_uno, "cara"}, {pid_cliente_dos, "hola"}] }

      MecanismoTransmision.Transmision.transmitir_msg(pid_cliente_uno, "hola mundo", :cliente)
      send pid_cliente_uno, { :respuestas, self }
      assert_receive { :estado, ["hola mundo"] }

      MecanismoTransmision.Transmision.transmitir_msg(pid_cliente_dos, "cara de bola", :cliente)
      send pid_cliente_dos, { :respuestas, self }
      assert_receive { :estado, ["cara de bola"] }
  end

end
