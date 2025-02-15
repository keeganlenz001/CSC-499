WIDTH = 80
HEIGHT = 160
GRID = 8

ROWS = 20
ROWS_BUFFER = 3
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
    for i = 1, ROWS + ROWS_BUFFER do
        table.insert(board, {})
        for j = 1, COLUMNS do
            table.insert(board[i], 0)
        end
    end

    function new_T_PIECE()
        return {
            shape ={
                {0, 0, 0},
                {1, 1, 1},
                {0, 1, 0}
            },
            position = {x = 4, y = 0}
        }
    end

    function new_J_PIECE() 
        return {
            shape = {
                {0, 0, 0},
                {1, 1, 1},
                {0, 0, 1},
            },
            position = {x = 4, y = 0}
        }
    end

    function new_Z_PIECE()
        return {
            shape = {
                {0, 0, 0},
                {1, 1, 0},
                {0, 1, 1}
            },
            position = {x = 4, y = 0}
        }
    end

    function new_O_PIECE()
        return {
            shape = {
                {0, 0, 0, 0},
                {0, 1, 1, 0},
                {0, 1, 1, 0},
                {0, 0, 0, 0}
            },
            position = {x = 3, y = 0}
        }
    end

    function new_S_PIECE()
        return {
            shape = {
                {0, 0, 0},
                {0, 1, 1},
                {1, 1, 0}
            },
            position = {x = 4, y = 0}
        }
    end

    function new_L_PIECE()
        return {
            shape = {
                {0, 0, 0},
                {1, 1, 1},
                {1, 0, 0}
            },
            position = {x = 4, y = 0}
        }
    end

    function new_I_PIECE()
        return {
            shape = {
                {0, 0, 0, 0},
                {1, 1, 1, 1},
                {0, 0, 0, 0},
                {0, 0, 0, 0}
            },
            position = {x = 3, y = 0}
        }
    end

    current_piece = new_I_PIECE()
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    for i = 1, COLUMNS + 1 do
        love.graphics.line(i * SCALED_GRID, 0, i * SCALED_GRID, HEIGHT * SCALED_GRID)
    end
    for i = 1, ROWS + 1 do
        love.graphics.line(0, i * SCALED_GRID, WIDTH * SCALED_GRID, i * SCALED_GRID)
    end

    for i = 1, table.getn(board) do
        for j = 1, table.getn(board[i]) do
            if board[i][j] == 1 then
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("fill", (j - 1) * SCALED_GRID, (i - 2) * SCALED_GRID, SCALED_GRID, SCALED_GRID)
            elseif board[i][j] == 2 then
                love.graphics.setColor(0.25, 0.25, 0.25)
                love.graphics.rectangle("fill", (j - 1) * SCALED_GRID, (i - 2) * SCALED_GRID, SCALED_GRID, SCALED_GRID)
            end
        end
    end
end

function new_piece()
    piece = math.random(7)

    if piece == 1 then
        current_piece = new_T_PIECE()
    elseif piece == 2 then
        current_piece = new_J_PIECE()
    elseif piece == 3 then
        current_piece = new_Z_PIECE()
    elseif piece == 4 then
        current_piece = new_O_PIECE()
    elseif  piece == 5 then
        current_piece = new_S_PIECE()
    elseif piece == 6 then
        current_piece = new_L_PIECE()
    elseif piece == 7 then
        current_piece = new_I_PIECE()
    end
end

function place_piece(board, piece)
    for i = 1, table.getn(piece.shape) do
        for j = 1, table.getn(piece.shape[i]) do
            if board[piece.position.y + i][piece.position.x + j] == 1 then
                board[piece.position.y + i][piece.position.x + j] = 2
            end
        end
    end

    new_piece()
end

function clear_piece(board, piece)
    for i = 1, table.getn(piece.shape) do
        for j = 1, table.getn(piece.shape[i]) do
            if board[piece.position.y + i][piece.position.x + j] == 1 then
                board[piece.position.y + i][piece.position.x + j] = 0
            end
        end
    end
end

function lower_piece(board, piece)
    for i = 1, table.getn(piece.shape) do
        for j = 1, table.getn(piece.shape[i]) do
            if board[piece.position.y + i][piece.position.x + j] == 2 and piece.shape[i][j] == 1 then
                place_piece(board, piece)
                return
            elseif board[piece.position.y + i][piece.position.x + j] == 0 and piece.shape[i][j] == 1 and piece.position.y + i > ROWS + 1 then
                piece.position.y = piece.position.y - 1
                place_piece(board, piece)
                return
            end
        end
    end

    clear_piece(board, piece)

    for i = 1, table.getn(piece.shape) do
        for j = 1, table.getn(piece.shape[i]) do
            if board[piece.position.y + i][piece.position.x + j] == 0 and piece.shape[i][j] == 1 then
                board[piece.position.y + i][piece.position.x + j] = 1
            end
        end
    end

    piece.position.y = piece.position.y + 1
end

function shift_piece(board, piece, dir)
    new_x = piece.position.x + dir

    if new_x < 0 or new_x + table.getn(piece.shape[1]) > COLUMNS then
        return
    end

    clear_piece(board, piece)
    piece.position.x = new_x

    for i = 1, table.getn(piece.shape) do
        for j = 1, table.getn(piece.shape[i]) do
            if board[piece.position.y + i][piece.position.x + j] == 0 and piece.shape[i][j] == 1 then
                board[piece.position.y + i][piece.position.x + j] = 1
            end
        end
    end
end

function love.update(dt)
    tick = tick + dt

    if tick > 0.25 then
        tick = 0
        lower_piece(board, current_piece)
    end

    if love.keyboard.isDown("s", "down") and tick > 0.025 then
        tick = 0
        lower_piece(board, current_piece)
    end

    function love.keypressed(key)
        if key == "a" or key == "left" then
            shift_piece(board, current_piece, -1)
        elseif key == "d" or key == "right" then
            shift_piece(board, current_piece, 1)
        end
    end
end