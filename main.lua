WIDTH = 80
HEIGHT = 160
GRID = 8

ROWS = 20
COLUMNS = 10

ROWS_BUFFER = 5
COLUMNS_BUFFER = 3
ROWS_OFFSET = 3
COLUMNS_OFFSET = 2

SCALE = 4

SCALED_GRID = GRID * SCALE

love.window.setMode(WIDTH * SCALE, HEIGHT * SCALE)

function love.load()
    tick = 0

    board = {}
    for i = 1, ROWS + ROWS_BUFFER do
        table.insert(board, {})
        for j = 1, COLUMNS + COLUMNS_BUFFER do
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
            position = {x = 5, y = 0}
        }
    end

    function new_J_PIECE() 
        return {
            shape = {
                {0, 0, 0},
                {1, 1, 1},
                {0, 0, 1},
            },
            position = {x = 5, y = 0}
        }
    end

    function new_Z_PIECE()
        return {
            shape = {
                {0, 0, 0},
                {1, 1, 0},
                {0, 1, 1}
            },
            position = {x = 5, y = 0}
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
            position = {x = 4, y = 0}
        }
    end

    function new_S_PIECE()
        return {
            shape = {
                {0, 0, 0},
                {0, 1, 1},
                {1, 1, 0}
            },
            position = {x = 5, y = 0}
        }
    end

    function new_L_PIECE()
        return {
            shape = {
                {0, 0, 0},
                {1, 1, 1},
                {1, 0, 0}
            },
            position = {x = 5, y = 0}
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
            position = {x = 4, y = 0}
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

    for i = 1, #board do
        for j = 1, #board[i] do
            if board[i][j] == 1 then
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("fill", (j - COLUMNS_OFFSET) * SCALED_GRID, (i - ROWS_OFFSET) * SCALED_GRID, SCALED_GRID, SCALED_GRID)
            elseif board[i][j] == 2 then
                love.graphics.setColor(0.25, 0.25, 0.25)
                love.graphics.rectangle("fill", (j - COLUMNS_OFFSET) * SCALED_GRID, (i - ROWS_OFFSET) * SCALED_GRID, SCALED_GRID, SCALED_GRID)
            end
        end
    end
end

function is_valid_position(board, piece)
    for i = 1, #piece.shape do
        for j = 1, #piece.shape[i] do
            if piece.shape[i][j] == 1 then
                -- Check for vertical bounds
                if piece.position.y + i > ROWS + ROWS_BUFFER - ROWS_OFFSET then
                    return false
                end

                -- Check for horizontal bounds
                if piece.position.x + j > COLUMNS + COLUMNS_BUFFER - COLUMNS_OFFSET or 
                   piece.position.x + j <= COLUMNS_BUFFER - COLUMNS_OFFSET then
                    return false
                end
                
                -- Check for collision with placed pieces
                if board[piece.position.y + i][piece.position.x + j] == 2 then
                    return false
                end
            end
        end
    end

    return true
end

function instantiate_piece(board, piece)
    for i = 1, #piece.shape do
        for j = 1, #piece.shape[i] do
            if board[piece.position.y + i][piece.position.x + j] == 0 and piece.shape[i][j] == 1 then
                board[piece.position.y + i][piece.position.x + j] = 1
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
    for i = 1, #piece.shape do
        for j = 1, #piece.shape[i] do
            if board[piece.position.y + i][piece.position.x + j] == 1 then
                board[piece.position.y + i][piece.position.x + j] = 2
            end
        end
    end

    new_piece()
end

function clear_piece(board, piece)
    for i = 1, #piece.shape do
        for j = 1, #piece.shape[i] do
            if board[piece.position.y + i][piece.position.x + j] == 1 then
                board[piece.position.y + i][piece.position.x + j] = 0
            end
        end
    end
end

function lower_piece(board, piece)
    clear_piece(board, piece)

    local original_y = piece.position.y
    piece.position.y = piece.position.y + 1

    if not is_valid_position(board, piece) then
        piece.position.y = original_y
        place_piece(board, piece)
    end

    instantiate_piece(board, piece)
end

function shift_piece(board, piece, dir)
    local original_x = piece.position.x
    piece.position.x = piece.position.x + dir

    if not is_valid_position(board, piece) then
        piece.position.x = original_x
        return
    end

    clear_piece(board, piece)
    instantiate_piece(board, piece)
end

function rotate_piece(board, piece, dir)
    rotated_shape = {}

    -- Creates empty table for rotated piece
    for i = 1, #piece.shape do
        rotated_shape[i] = {}
        for j = 1, #piece.shape[i] do
            rotated_shape[i][j] = 0
        end
    end

    -- Fills rotated_shape with the rotated piece
    for i = 1, #piece.shape do
        for j = 1, #piece.shape[i] do
            if dir == 1 then
                rotated_shape[j][#piece.shape - i + 1] = piece.shape[i][j]  -- Clockwise
            else
                rotated_shape[#piece.shape - j + 1][i] = piece.shape[i][j]  -- Counterclockwise
            end
        end
    end

    -- Store the original shape in case we need to revert
    local original_shape = piece.shape
    piece.shape = rotated_shape

    local original_x = piece.position.x

    -- Check if the rotation is valid in current position
    if not is_valid_position(board, piece) then
        local shift_success = false
        
        -- Try different wall kicks (offsets)
        local kicks = {-1, 1, -2, 2}  -- Try closer offsets first
        
        for _, kick in ipairs(kicks) do
            -- Apply the kick offset
            piece.position.x = original_x + kick
            
            -- Check if this position is valid
            if is_valid_position(board, piece) then
                shift_success = true
                break
            end
        end
        
        -- If no valid position was found, revert rotation
        if not shift_success then
            piece.shape = original_shape
            piece.position.x = original_x
        end
    end
    
    -- Clear and redraw board with rotated piece
    clear_piece(board, piece)
    instantiate_piece(board, piece)
end



function love.keypressed(key)
    -- Debug
    if love.keyboard.isDown("s", "down") then
        lower_piece(board, current_piece)
    end

    if key == "a" or key == "left" then
        shift_piece(board, current_piece, -1)
    elseif key == "d" or key == "right" then
        shift_piece(board, current_piece, 1)
    elseif key == "q" then
        rotate_piece(board, current_piece, -1)
    elseif key == "e" then
        rotate_piece(board, current_piece, 1)
    end
end

function love.update(dt)
    tick = tick + dt

    -- if tick > 0.25 then
    --     tick = 0
    --     lower_piece(board, current_piece)
    -- end

    -- if love.keyboard.isDown("s", "down") and tick > 0.025 then
    --     tick = 0
    --     lower_piece(board, current_piece)
    -- end
end