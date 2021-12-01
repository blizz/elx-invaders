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

  
  def row_of_invaders(row,count,invader) do
    for i <- 0..(count-1), do: [row,i,invader,5]
  end

  def multi_rows(grid,rows,cols,current_row,invader) do
    case current_row do
      0 -> [ row_of_invaders(current_row,cols,invader) | grid ]
      _ -> [ row_of_invaders(current_row,cols,invader) | multi_rows(grid,rows,cols,current_row-1,invader) ]
    end
  end


  def grid_of_invaders(rows,cols) do
    top_rows = [ row_of_invaders(rows-1,cols,["<=>"]),
                 row_of_invaders(rows-2,cols,["<o>"]) ]
    multi_rows(top_rows,rows,cols,rows-3,["<x>"])
  end


  def run_invaders do
    clear_screen()
    grid_of_invaders(5,10)
  end

end
