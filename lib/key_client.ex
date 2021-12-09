defmodule KeyClient do

  def handle_connect( { :ok,     socket           },  pid ), do: loop_recv( socket,{:ok, "start receiving"}, pid )
  def handle_connect( { :error, :econnrefused     }, _pid ), do: nil
  def handle_connect( { :error,  err              }, _pid ), do: IO.inspect err

  def recv(port,pid) do
    #IO.puts "  SETTING UP SOCKDETSETTING UP SOCKDETSETTING UP SOCKDETSETTING UP SOCKDETSETTING UP SOCKDETSETTING UP SOCKDETSETTING UP SOCKDET"
    opts = [:binary, active: false]
    handle_connect( :gen_tcp.connect('localhost', port, opts), pid )
  end

  def send_key_message(  pid, "P25\n"  ), do: send( pid, { :left_pressed   } )
  def send_key_message(  pid, "P40\n"  ), do: send( pid, { :right_pressed  } )
  def send_key_message(  pid, "r25\n"  ), do: send( pid, { :left_released  } )
  def send_key_message(  pid, "r40\n"  ), do: send( pid, { :right_released } )
  def send_key_message( _pid, keypress ), do: IO.puts "Unknown keypress: #{keypress}"

  def handle_result( _socket,  {:error, :closed},    _pid ), do: IO.puts "connection closed"
  def handle_result(  socket,  {:ok, text}      ,     pid )  do
    #IO.puts text  # left 25, right 40 fire 3e
    send_key_message( pid, text )
    
    receive do 
      { :terminate } -> nil
    after
      0 -> loop_recv( socket, {:ok, text}, pid)
    end      
    
  end


  def loop_recv(_socket,{:error, err   }, _pid ), do: IO.inspect(err)
  def loop_recv( socket,{:ok,    _text },  pid )  do
    handle_result( socket, :gen_tcp.recv(socket, 4), pid )
  end


end
