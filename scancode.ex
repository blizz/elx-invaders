import ExCmd
defmodule A do
  def main do 
    proc_stream = ExCmd.stream!( "sudo", ["showkey", "--scancodes"] )
    Enum.map(proc_stream,fn line -> IO.puts line end)
  end
end
