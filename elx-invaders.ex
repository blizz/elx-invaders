# test terminal control

defmodule T do
  def main do
    cursor_off()
    run_invaders()
    cursor_on()
  end

  def draw(_row, _col, []), do: 0

  def draw(row, col, [h | t]) do
    position(row, col)
    IO.write(h)
    draw(row + 1, col, t)
  end

  def move(terminal_code, number_of_spaces) do
    # using terminal escape sequence to move cursor
    IO.write("\e[" <> to_string(number_of_spaces) <> terminal_code)
  end

  def up(rows), do: move("A", rows)
  def dn(rows), do: move("B", rows)
  def rt(cols), do: move("C", cols)
  def lf(cols), do: move("D", cols)

  def position(row, col) do
    # using terminal escape sequence to Position cursor
    IO.write("\e[" <> to_string(row) <> ";" <> to_string(col) <> "H")
  end

  def clear_screen do
    IO.write("\e[2J")
  end

  def cursor_off, do: IO.write("\e[?25l")
  def cursor_on,  do: IO.write("\e[?25h")

  def row_of_invaders(row, count, invader) do
    for i <- (count - 1)..0, do: [row, i, invader, 5]
  end

  def multi_rows(rows, cols, current_row, invader) do
    case current_row do
      0 ->
        [row_of_invaders(current_row, cols, invader)]

      _ ->
        [
          row_of_invaders(current_row, cols, invader)
          | multi_rows(rows, cols, current_row - 1, invader)
        ]
    end
  end

  def grid_of_invaders(rows, cols) do
    extra_rows = multi_rows( rows, cols, rows - 3, ["<:>"] )
    top_rows   = [
      row_of_invaders(rows - 1, cols,    ["<=>"]),
      row_of_invaders(rows - 2, cols,    ["<o>"])
    ]
    top_rows ++ extra_rows
  end

  def draw_column_of_invaders(         _,         _,      _,      _, []             ), do: nil
  def draw_column_of_invaders(row_offset,col_offset,was_row,was_col, [invader|tail] )  do
    [row,col,spaceship,_status] = invader
    position(was_row + row, was_col + (col * 5))
    IO.write("   ")
    position(row_offset + row, col_offset + (col * 5))
    IO.write(spaceship)
    :timer.sleep(50)
    draw_column_of_invaders(row_offset,col_offset,was_row,was_col,tail)
  end

  def draw_invaders(                 _,         _,      _,      _, []                     ), do: nil
  def draw_invaders(        row_offset,col_offset,was_row,was_col, [col_of_invaders|tail] )  do
    draw_column_of_invaders(row_offset,col_offset,was_row,was_col,  col_of_invaders       )
    draw_invaders(row_offset,col_offset,was_row,was_col,tail)
  end

  def march_invaders(row_offset,col_offset,was_row,was_col,goi) do
    draw_invaders(   row_offset,col_offset,was_row,was_col,goi)
    case col_offset do

      n when n > 5 -> nil

                 _ -> ( :timer.sleep(300) ; 
                        march_invaders(row_offset, col_offset + 1 ,
                                       row_offset, col_offset     ,goi) )
    end
  end

  def run_invaders do
    clear_screen()
    goi = grid_of_invaders(5, 10)
    march_invaders(5,3,5,3,goi)
    dn(5)
  end
end
