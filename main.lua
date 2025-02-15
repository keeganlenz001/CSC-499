WIDTH = 80
HEIGHT = 160
GRID = 8

ROWS = 24
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

    T_PIECE = {
        -- Initial shape
        {
            {0, 0, 0},
            {1, 1, 1},
            {0, 1, 0}
        },
        -- (x, y) coordinates
        {4, 0}
    }

    J_PIECE = {
        {
            {0, 0, 0},
            {1, 1, 1},
            {0, 0, 1},
        },
        {4, 0}
    }

    Z_PIECE = {
        {
            {0, 0, 0},
            {1, 1, 0},
            {0, 1, 1}
        },
        {4, 0}
    }

    O_PIECE = {
        {
            {0, 0, 0, 0},
            {0, 1, 1, 0},
            {0, 1, 1, 0},
            {0, 0, 0, 0}
        },
        {3, 0}
    }

    S_PIECE = {
        {
            {0, 0, 0},
            {0, 1, 1},
            {1, 1, 0}
        },
        {4, 0}
    }

    L_PIECE = {
        {
            {0, 0, 0},
            {1, 1, 1},
            {1, 0, 0}
        },
        {4, 0}
    }

    I_PIECE = {
        {
            {0, 0, 0, 0},
            {1, 1, 1, 1},
            {0, 0, 0, 0},
            {0, 0, 0, 0}
        },
        {3, 0}
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
                love.graphics.rectangle("fill", (j - 1) * SCALED_GRID, (i - 2) * SCALED_GRID, SCALED_GRID, SCALED_GRID)
            end
        end
    end
end

function clear_piece(board, piece)
    piece_x = piece[2][1]
    piece_y = piece[2][2]

    for i = 1, table.getn(piece[1]) do
        for j = 1, table.getn(piece[1][i]) do
            if board[piece_y + i][piece_x + j] == 1 then
                board[piece_y + i][piece_x + j] = 0
            end
        end
    end
end

function lower_piece(board, piece)
    clear_piece(board, piece)

    piece_x = piece[2][1]
    piece_y = piece[2][2]

    for i = 1, table.getn(piece[1]) do
        for j = 1, table.getn(piece[1][i]) do
            if board[piece_y + i][piece_x + j] == 0 and piece[1][i][j] == 1 then
                board[piece_y + i][piece_x + j] = 1
            end
        end
    end

    piece[2][2] = piece[2][2] + 1
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
        tick = 0
        lower_piece(board, I_PIECE)
    end

    function love.keypressed(key)
        if key == "a" or key == "left" then
            check_xdirection(-1)
        elseif key == "d" or key == "right" then
            check_xdirection(1)
        end
    end
end