defmodule ElxInvaders do
  require Mutex
  @moduledoc """
  Documentation for `ElxInvaders`.
  """

  @doc """
    ElxInvaders

  """

  def main do

    children = [
      { Mutex, name: MyMutex, meta: "some_data" }
    ]

    {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)    

    #strm = ExCmd.stream!(["cat","/dev/input/event2"],[exit_timeout: 100, chunk_size: 6])

    #test_ex_cmd(strm)

    screen_mutex = {Screen, {:id, 1}}

    cursor_off()
    run_invaders(screen_mutex)
    cursor_on()
  end

  def test_ex_cmd(strm) do
    #strm = ExCmd.stream!("showkey --scancodes")
    IO.inspect(strm)
    Enum.map(strm,fn line -> IO.puts Base.encode16(line) end )
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

  def clear_screen(screen_mutex) do
    lock = Mutex.await( MyMutex, screen_mutex )
    IO.write("\e[2J")
    Mutex.release(      MyMutex, lock )
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

  def draw_column_of_invaders(          _,         _,      _,      _, []            ,_   ,       _      ), do: nil
  def draw_column_of_invaders( row_offset,col_offset,was_row,was_col, [invader|tail], dbt, screen_mutex )  do
    [row,col,spaceship,_status] = invader
    lock = Mutex.await( MyMutex, screen_mutex )
    position(was_row + row, was_col + (col * 5))
    IO.write("   ")
    position(row_offset + row, col_offset + (col * 5))
    IO.write(spaceship)
    Mutex.release(      MyMutex, lock )

    if :rand.uniform(100) < 5 do
      send(dbt, {:add_bomb, [was_row+row,was_col+(col*5),1]} )
    end

    :timer.sleep(5)
    draw_column_of_invaders(   row_offset,col_offset,was_row,was_col, tail                , dbt, screen_mutex )
  end

  def draw_invaders(                 _,         _,      _,      _,   []                   ,_   , _            ), do: nil
  def draw_invaders(         row_offset,col_offset,was_row,was_col, [col_of_invaders|tail], dbt, screen_mutex )  do
    draw_column_of_invaders( row_offset,col_offset,was_row,was_col,  col_of_invaders      , dbt, screen_mutex )
    :timer.sleep(25)
    draw_invaders(           row_offset,col_offset,was_row,was_col,  tail                 , dbt, screen_mutex )
  end

  def inner_march( cycle, row_offset, col_offset, goi, dbt, screen_mutex ) do
    System.cmd("bash",["-c","play march" <> to_string(cycle) <> ".mp3 1>/dev/null 2>/dev/null"])
    :timer.sleep(150)
    case cycle do
      n when n > 2 -> march_invaders(         0, row_offset, col_offset + 1, row_offset, col_offset, goi, dbt, screen_mutex )
                 _ -> march_invaders( cycle + 1, row_offset, col_offset + 1, row_offset, col_offset, goi, dbt, screen_mutex )
    end
  end

  def march_invaders( cycle, row_offset,col_offset,was_row,was_col,goi,dbt,screen_mutex ) do
    draw_invaders(           row_offset,col_offset,was_row,was_col,goi,dbt,screen_mutex )
    case col_offset do

      n when n > 11 -> nil

                 _ -> inner_march( cycle, row_offset, col_offset, goi, dbt, screen_mutex )
    end
  end

  def move_bomb_func( [[row,col,direction], screen_mutex] ) do
    lock = Mutex.await( MyMutex, screen_mutex )

    ElxInvaders.position(row,col)
    IO.write(" ")

    if row==25 do
      Mutex.release(      MyMutex, lock )
      nil
    else
      ElxInvaders.position(row+direction,col)
      IO.write(".")
      Mutex.release(      MyMutex, lock )
      [row+direction,col,direction]
    end

  end


  def dropped_bombs_thread(bombs,screen_mutex) do
    receive do 
      { :add_bomb, bomb } -> dropped_bombs_thread( [ bomb | bombs ], screen_mutex )
      { :terminate }      -> nil
    after
      500 -> dropped_bombs_thread( Enum.map( Enum.map(bombs,fn bomb -> [bomb,screen_mutex] end), &move_bomb_func/1 ), screen_mutex )
    end
  end

  def spaceship_thread([row,col,direction],screen_mutex) do
    lock = Mutex.await( MyMutex, screen_mutex )
    ElxInvaders.position(row,col)
    IO.write("   ")
    ElxInvaders.position(row,col+direction)
    IO.write("=^=")
    Mutex.release(      MyMutex, lock )
    receive do 
      { :explode }   -> System.cmd("bash",["-c","play ship_exploding.mp3 1>/dev/null 2>/dev/null"]) 
      { :terminate } -> nil
    after
      100 -> spaceship_thread([row,col+direction,direction],screen_mutex)
    end      
  end

  def run_invaders(screen_mutex) do
    clear_screen(screen_mutex)
    goi = grid_of_invaders(5, 10)

    dbt = spawn( fn -> dropped_bombs_thread(     [ ]    , screen_mutex ) end )
    spc = spawn( fn -> spaceship_thread(     [25, 2, 1] , screen_mutex ) end )

    march_invaders(0,5,3,5,3,goi,dbt,screen_mutex)

    #Process.sleep(10000)

    send( dbt, { :terminate } )
    send( spc, { :terminate } )

    dn(5)
  end



end
