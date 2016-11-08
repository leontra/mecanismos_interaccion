defmodule MecanismoTransmision.TransmisionTest do
  use ExUnit.Case, async: true

  @doctest """
    Estos primeros tests están hechos para la
    interacción entre un solo cliente y una sola fábrica
  """
  test "iniciar conexion por parte de un solo cliente" do
      assert {:ok, true} = MecanismoTransmision.Transmision.start_link(:cliente, :cliente_uno)
  end

  test "iniciar conexion por parte de una sola fabrica" do
      assert {:ok, _pid} = MecanismoTransmision.Fabrica.start()
  end

  test "transmitir un msg del cliente hacia la fabrica" do
      MecanismoTransmision.Transmision.start_link(:cliente, :cliente_uno)
      MecanismoTransmision.Fabrica.start()

      assert {:ok, :mensaje_transmitido} = MecanismoTransmision.Transmision.transmitir_msg(:cliente, "Hola cara de bola", :fabrica)
  end

  test "transmitir un msg del cliente hacia la fabrica y la fabrica lo recibe" do
      MecanismoTransmision.Transmision.start_link(:cliente, :cliente_uno)
      {:ok, pid_fabrica} = MecanismoTransmision.Fabrica.start()
      MecanismoTransmision.Transmision.transmitir_msg(:cliente, "Hola cara de torta", :fabrica)

      assert {:ok, :incoming, "Hola cara de torta"} = MecanismoTransmision.Fabrica.estado(pid_fabrica)
      task = Task.async(fn -> :algo end)
      ref  = Process.monitor(task.pid)
      assert_receive {:DOWN, ^ref, :process, _, :normal}, 1500
  end

  def probar_estado(pid_fabrica) do
      #assert {:ok, :incoming, "Hola cara de torta"} =
      MecanismoTransmision.Fabrica.estado(pid_fabrica)
  end


  @doctest """
  Estos otros tests son para iniciar la conexión hacia el mecanismo de Transmision
  de un o varios clientes
  """

end
