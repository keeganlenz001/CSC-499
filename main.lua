BOARD_WIDTH = 80
BOARD_HEIGHT = 160
PADDING = 16
GRID = 8

ROWS = 20
COLUMNS = 10
DEPTH = 4

ROWS_BUFFER = 3
COLUMNS_BUFFER = 3
ROWS_OFFSET = 2
COLUMNS_OFFSET = 2

SCALE = 3

SCALED_GRID = GRID * SCALE

WIDTH = (BOARD_WIDTH * DEPTH * SCALE) + (PADDING * (DEPTH + 1))
HEIGHT = (BOARD_HEIGHT * SCALE) + (PADDING * 2)
love.window.setMode(WIDTH, HEIGHT)

function love.load()
    tick = 0

    board = {}
    for i = 1, DEPTH do
        table.insert(board, {})
        for j = 1, ROWS + ROWS_BUFFER do
            table.insert(board[i], {})
            for k = 1, COLUMNS + COLUMNS_BUFFER do
                table.insert(board[i][j], 0)
            end
        end
    end

    local function get_shape3D(shape)
        local shape3D = {}
        shape3D[1] = shape

        for depth = 2, #shape do
            shape3D[depth] = {}
            for i = 1, #shape do
                shape3D[depth][i] = {}
                for j = 1, #shape[i] do
                    shape3D[depth][i][j] = 0
                end
            end
        end

        return shape3D
    end

    function new_T_PIECE()
        local shape = {
            {0, 0, 0},
            {1, 1, 1},
            {0, 1, 0}
        }

        return {
            shape = get_shape3D(shape),
            position = {x = 5, y = 0, z = 0}
        }
    end

    function new_J_PIECE() 
        local shape = {
            {0, 0, 0},
            {1, 1, 1},
            {0, 0, 1},
        }

        return {
            shape = get_shape3D(shape),
            position = {x = 5, y = 0, z = 0}
        }
    end

    function new_Z_PIECE()
        local shape = {
            {0, 0, 0},
            {1, 1, 0},
            {0, 1, 1}
        }

        return {
            shape = get_shape3D(shape),
            position = {x = 5, y = 0, z = 0}
        }
    end

    function new_O_PIECE()
        local shape = {
            {0, 0, 0, 0},
            {0, 1, 1, 0},
            {0, 1, 1, 0},
            {0, 0, 0, 0}
        }

        return {
            shape = get_shape3D(shape),
            position = {x = 4, y = 0, z = 0}
        }
    end

    function new_S_PIECE()
        local shape = {
            {0, 0, 0},
            {0, 1, 1},
            {1, 1, 0}
        }

        return {
            shape = get_shape3D(shape),
            position = {x = 5, y = 0, z = 0}
        }
    end

    function new_L_PIECE()
        local shape = {
            {0, 0, 0},
            {1, 1, 1},
            {1, 0, 0}
        }

        return {
            shape = get_shape3D(shape),
            position = {x = 5, y = 0, z = 0}
        }
    end

    function new_I_PIECE()
        local shape = {
            {0, 0, 0, 0},
            {1, 1, 1, 1},
            {0, 0, 0, 0},
            {0, 0, 0, 0}
        }

        return {
            shape = get_shape3D(shape),
            position = {x = 4, y = 0, z = 0}
        }
    end

    current_piece = new_I_PIECE()
    set_piece(board, current_piece)
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    for depth = 0, DEPTH - 1 do
        local x_offset = depth * (COLUMNS * SCALED_GRID + PADDING) + PADDING
        local y_offset = PADDING

        -- Draw horizontal lines
        for row = 0, ROWS do
            local y = y_offset + (row * SCALED_GRID)
            love.graphics.line(x_offset, y, x_offset + COLUMNS * SCALED_GRID, y)
        end

        -- Draw vertical lines
        for column = 0, COLUMNS do
            local x = x_offset + (column * SCALED_GRID)
            love.graphics.line(x, y_offset, x, y_offset + ROWS * SCALED_GRID)
        end
    end

    for depth = 1, #board do
        local x_offset = depth * (COLUMNS * SCALED_GRID + PADDING) + PADDING
        local y_offset = PADDING

        for row = 1, #board[depth] do
            for column = 1, #board[depth][row] do
                if board[depth][row][column] == 1 then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.rectangle("fill", x_offset + ((column - COLUMNS_OFFSET) * SCALED_GRID), y_offset + ((row - ROWS_OFFSET) * SCALED_GRID), SCALED_GRID, SCALED_GRID)
                elseif board[depth][row][column] == 2 then
                    love.graphics.setColor(0.25, 0.25, 0.25)
                    love.graphics.rectangle("fill", x_offset + ((column - COLUMNS_OFFSET) * SCALED_GRID), y_offset + ((row - ROWS_OFFSET) * SCALED_GRID), SCALED_GRID, SCALED_GRID)
                end
            end
        end
    end
end

function line_clear(board)
    local line_clear_count = 0 -- Will be used for scoring

    for depth = 1, #board do
        for row = 1, #board[depth] do
            full_line = true
            for column = COLUMNS_OFFSET, #board[depth][row] - COLUMNS_BUFFER + 1 do
                if board[depth][row][column] ~= 2 then
                    full_line = false
                end
            end

            if full_line then
                line_clear_count = line_clear_count + 1

                -- Move all rows above this line down by one row
                for i = row, 2, -1 do  -- Start from the cleared line and move upward
                    for j = 1, #board[i] do
                        board[i][j] = board[i - 1][j]  -- Copy from row above
                    end
                end
                
                -- Don't increment i since we need to check the same row again
                -- (since we just moved a new row into this position)
                row = row - 1
            end
        end
    end
end

function is_valid_position(board, piece)
    for depth = 1, #piece.shape do
        for row = 1, #piece.shape[depth] do
            for column = 1, #piece.shape[depth][row] do

                if piece.shape[depth][row][column] == 1 then
                    -- Check for vertical bounds
                    if piece.position.y + row > ROWS + ROWS_BUFFER - ROWS_OFFSET then
                        return false
                    end

                    -- Check for horizontal bounds
                    if piece.position.x + column > COLUMNS + COLUMNS_BUFFER - COLUMNS_OFFSET or 
                    piece.position.x + column <= COLUMNS_BUFFER - COLUMNS_OFFSET then
                        return false
                    end
                    
                    -- Check for collision with placed pieces
                    if board[depth][piece.position.y + i][piece.position.x + j] == 2 then
                        return false
                    end
                end
            end
        end
    end

    return true
end

function set_piece(board, piece)
    for depth = 1, #piece.shape do
        for row = 1, #piece.shape[depth] do
            for column = 1, #piece.shape[depth][row] do
                if board[depth][piece.position.y + row][piece.position.x + column] == 0 and piece.shape[depth][row][column] == 1 then
                    board[depth][piece.position.y + row][piece.position.x + column] = 1
                end
            end
        end
    end
end

function new_piece()
    -- Debug
    current_piece = new_I_PIECE()

    -- piece = math.random(7)

    -- if piece == 1 then
    --     current_piece = new_T_PIECE()
    -- elseif piece == 2 then
    --     current_piece = new_J_PIECE()
    -- elseif piece == 3 then
    --     current_piece = new_Z_PIECE()
    -- elseif piece == 4 then
    --     current_piece = new_O_PIECE()
    -- elseif  piece == 5 then
    --     current_piece = new_S_PIECE()
    -- elseif piece == 6 then
    --     current_piece = new_L_PIECE()
    -- elseif piece == 7 then
    --     current_piece = new_I_PIECE()
    -- end

    set_piece(board, current_piece)
end

function place_piece(board, piece)
    for depth = 1, #piece.shape do
        for row = 1, #piece.shape[depth] do
            for column = 1, #piece.shape[depth][row] do
                if board[depth][piece.position.y + row][piece.position.x + column] == 0 and piece.shape[depth][row][column] == 1 then
                    board[depth][piece.position.y + row][piece.position.x + column] = 2
                end
            end
        end
    end

    line_clear(board)
    new_piece()
end

function clear_piece(board, piece)
    for depth = 1, #piece.shape do 
        for row = 1, #piece.shape[depth] do
            for column = 1, #piece.shape[depth][row] do
                if board[depth][piece.position.y + row][piece.position.x + column] == 1 then
                    board[depth][piece.position.y + row][piece.position.x + column] = 0
                end
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
        return
    end

    set_piece(board, piece)
end

function shift_piece(board, piece, dir)
    clear_piece(board, piece)

    local original_x = piece.position.x
    piece.position.x = piece.position.x + dir

    if not is_valid_position(board, piece) then
        piece.position.x = original_x
    end

    set_piece(board, piece)
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
    set_piece(board, piece)
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

    if love.keyboard.isDown("s", "down") and tick > 0.025 then
        tick = 0
        lower_piece(board, current_piece)
    end
end