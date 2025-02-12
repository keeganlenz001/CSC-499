WIDTH = 80
HEIGHT = 160
GRID = 8

ROWS = 20
COLUMNS = 10

SCALE = 4

SCALED_GRID = GRID * SCALE

love.window.setMode(WIDTH * SCALE, HEIGHT * SCALE)

function love.load()
    tick = 0

    block = {
        x = 0,
        y = 0
    }

    board = {}
    for i = 1, ROWS do
        table.insert(board, {})
        for j = 1, COLUMNS do
            table.insert(board[i], 0)
        end
    end

    board[1][1] = 1

    T_PIECE = {
        
    }
end

function love.draw()
    for i = 1, COLUMNS + 1 do
        love.graphics.line(i * SCALED_GRID, 0, i * SCALED_GRID, HEIGHT * SCALED_GRID)
    end
    for i = 1, ROWS + 1 do
        love.graphics.line(0, i * SCALED_GRID, WIDTH * SCALED_GRID, i * SCALED_GRID)
    end

    for i = 1, table.getn(board) do
        for j = 1, table.getn(board[i]) do
            if board[i][j] == 1 then
                love.graphics.rectangle("fill", (j - 1) * SCALED_GRID, (i - 1) * SCALED_GRID, SCALED_GRID, SCALED_GRID)
            end
        end
    end
end

function check_xdirection(dir)
    for i = 1, table.getn(board) do
        for j = 1, table.getn(board[i]) do
            if board[i][j] == 1 and j + dir > 0 and j + dir < COLUMNS + 1 then
                if board[i][j + dir] == 0 then
                    board[i][j] = 0
                    board[i][j + dir] = 1
                    break
                end
            end
        end
    end
end

function love.update(dt)
    tick = tick + dt

    if tick > 1 then
        for i = 1, table.getn(board) do
            for j = 1, table.getn(board[i]) do
                if board[i][j] == 1 and i + 1 < ROWS + 1 then
                    if board[i + 1][j] == 0 then
                        board[i][j] = 0
                        board[i + 1][j] = 1
                        tick = 0
                        return
                    end
                end
            end
        end
    end

    function love.keypressed(key)
        if key == "a" or key == "left" then
            check_xdirection(-1)
        elseif key == "d" or key == "right" then
            check_xdirection(1)
        end
    end
end