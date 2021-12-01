#test terminal control


defmodule T do

  def main do
    run_invaders()
  end

  def draw(_row,_col,[]), do: 0
  def draw(row,col,[h|t]) do
    position(row,col)
    IO.write(h)
    draw(row+1,col,t)
  end

  def move(terminal_code,number_of_spaces) do
    # using terminal escape sequence to move cursor
    IO.write "\e[" <> to_string(number_of_spaces) <> terminal_code
  end

  def up(rows), do: move("A",rows)
  def dn(rows), do: move("B",rows)
  def rt(cols), do: move("C",cols)
  def lf(cols), do: move("D",cols)

  def position(row,col) do
    # using terminal escape sequence to Position cursor
    IO.write "\e[" <> to_string(row) <> ";" <> to_string(col) <> "H"
  end

  def clear_screen do
    IO.write "\e[2J"
  end


  def run_invaders do
    up(20)
    IO.puts "hello================================="
    dn(5)
    IO.puts "there+++++++++++++++++++++++++++++"
    position(10,30)
    clear_screen()
    draw(10,10,['xxx','XOX','XXX'])
    dn(5)
    nil
  end

end
