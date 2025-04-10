BOARD_WIDTH = 80
BOARD_HEIGHT = 160
-- PADDING = 16
GRID = 8

ROWS = 20
COLUMNS = 10
DEPTH = 4

ROW_BUFFER = 3
COLUMN_BUFFER = 3
DEPTH_BUFFER = 3

ROW_OFFSET = 2
COLUMN_OFFSET = 2
DEPTH_OFFSET = 2 -- Every piece is on the second depth layer

SCALE = 3

SCALED_GRID = GRID * SCALE
PADDING = SCALED_GRID

-- Alternate UI layout
-- INFO_PANEL = 40
INFO_PANEL = 80
FONT_SIZE = 24

WIDTH = (BOARD_WIDTH * DEPTH * SCALE) + (PADDING * (DEPTH + 1))
HEIGHT = (BOARD_HEIGHT * SCALE) + (PADDING * 2) + (INFO_PANEL + PADDING)
love.window.setMode(WIDTH, HEIGHT)

ACTIVE_PIECE_VALUE = 1
GHOST_PIECE_VALUE = 2
PLACED_PIECE_VALUE = 3

function love.load()
    tick = 0
    level = 0
    score = 0
    high_score_file = "high_score.txt"

    if not love.filesystem.getInfo(high_score_file) then
        love.filesystem.write(high_score_file, "0")
    end

    high_score = tonumber(love.filesystem.read(high_score_file), 10) or 0

    nes_font = love.graphics.newFont("nintendo-nes-font.ttf", FONT_SIZE)

    board = {}
    for i = 1, DEPTH + DEPTH_BUFFER do
        table.insert(board, {})
        for j = 1, ROWS + ROW_BUFFER do
            table.insert(board[i], {})
            for k = 1, COLUMNS + COLUMN_BUFFER do
                table.insert(board[i][j], 0)
            end
        end
    end

    local function get_shape3D(shape)
        local shape3D = {}

        for depth = 1, #shape do
            if depth == math.ceil(#shape / 2) then
                shape3D[depth] = shape
            else
                shape3D[depth] = {}

                for row = 1, #shape do
                    shape3D[depth][row] = {}
                    for column = 1, #shape[row] do
                        shape3D[depth][row][column] = 0
                    end
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
            position = {x = 5, y = 0, z = math.ceil(DEPTH / 2) - 1}
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
            position = {x = 5, y = 0, z = math.ceil(DEPTH / 2) - 1}
        }
    end

    function new_Z_PIECE()
        local shape = {
            {0, 0, 0},
            {1, 1, 0},
            {0, 1, 1}

            -- {1, 1, 0},
            -- {0, 1, 1},
            -- {0, 0, 0}

            -- {0, 0, 1},
            -- {0, 1, 1},
            -- {0, 1, 0}
        }

        return {
            shape = get_shape3D(shape),
            position = {x = 5, y = 0, z = math.ceil(DEPTH / 2) - 1}
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
            position = {x = 4, y = 0, z = math.ceil(DEPTH / 2) - 1}
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
            position = {x = 5, y = 0, z = math.ceil(DEPTH / 2)  - 1}
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
            position = {x = 5, y = 0, z = math.ceil(DEPTH / 2) - 1}
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
            position = {x = 4, y = 0, z = math.ceil(DEPTH / 2)  - 1}
        }
    end

    function new_DEBUG_PIECE()
        local shape = {
            {
                {0, 1, 0},
                {0, 0, 0},
                {0, 0, 0} 
            },
            {
                {0, 1, 0},
                {0, 1, 0},
                {0, 0, 0} 
            },
            {
                {0, 0, 0},
                {0, 1, 0},
                {0, 0, 0} 
            }
        }

        return {
            shape = shape,
            position = {x = 4, y = 0, z = math.ceil(DEPTH / 2) - 1}
        }
    end

    next_piece = piece_by_id(math.random(7))
    new_piece()
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 1) -- White text
    love.graphics.setFont(nes_font)

    -- High Score
    formatted_top = string.format("%06d", high_score)
    love.graphics.print("TOP", PADDING, PADDING)
    love.graphics.print(formatted_top, PADDING, PADDING + FONT_SIZE)

    -- Score
    formatted_score = string.format("%06d", score)
    -- love.graphics.print("SCORE", PADDING * 8, PADDING) -- Alternate UI Layout
    -- love.graphics.print(formatted_score, PADDING * 8, PADDING + FONT_SIZE) -- Alternate UI Layout
    love.graphics.print("SCORE", PADDING, PADDING + (FONT_SIZE * 2))
    love.graphics.print(formatted_score, PADDING, PADDING + (FONT_SIZE * 3))

    -- Next Piece
    -- love.graphics.print("NEXT", PADDING * 16, PADDING) -- Alternate UI Layout
    love.graphics.print("NEXT", PADDING * 12, PADDING)
    for depth = 1, #next_piece.shape do
            -- local x_offset = PADDING * 24 -- Alternate UI Layout
            -- local y_offset = PADDING -- Alternate UI Layout
            local x_offset = PADDING * 13
            local y_offset = PADDING + FONT_SIZE + (PADDING / 2)
        for row = 1, #next_piece.shape[depth] do
            for column = 1, #next_piece.shape[depth][row] do
                local x = x_offset + ((column - COLUMN_OFFSET) * SCALED_GRID)
                local y = y_offset + ((row - ROW_OFFSET) * SCALED_GRID)

                if next_piece.shape[depth][row][column] == 1 then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.rectangle("fill", x, y, SCALED_GRID, SCALED_GRID)
                end
            end
        end
    end

    -- Draw grids
    for depth = 1, DEPTH do
        love.graphics.setColor(1, 1, 1)
        local x_offset = (depth - 1) * (COLUMNS * SCALED_GRID + PADDING) + PADDING
        local y_offset = PADDING + INFO_PANEL + PADDING

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

    -- Draw blocks
    for depth = 1, #board do
        local x_offset = (depth - DEPTH_OFFSET) * (COLUMNS * SCALED_GRID + PADDING) + PADDING
        local y_offset = PADDING + INFO_PANEL + PADDING
        
        for row = 1, #board[depth] do
            for column = 1, #board[depth][row] do
                local x = x_offset + ((column - COLUMN_OFFSET) * SCALED_GRID)
                local y = y_offset + ((row - ROW_OFFSET) * SCALED_GRID)

                if board[depth][row][column] == ACTIVE_PIECE_VALUE then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.rectangle("fill", x, y, SCALED_GRID, SCALED_GRID)
                elseif board[depth][row][column] == GHOST_PIECE_VALUE then
                    love.graphics.setColor(1, 1, 1, 0.3)
                    love.graphics.rectangle("fill", x, y, SCALED_GRID, SCALED_GRID)
                elseif board[depth][row][column] == PLACED_PIECE_VALUE then
                    love.graphics.setColor(0.25, 0.25, 0.25)
                    love.graphics.rectangle("fill", x, y, SCALED_GRID, SCALED_GRID)
                end
            end
        end
    end
end

function set_piece(board, piece)
    for depth = 1, #piece.shape do
        for row = 1, #piece.shape[depth] do
            for column = 1, #piece.shape[depth][row] do
                local current_position = board[piece.position.z + depth][piece.position.y + row][piece.position.x + column]
                if current_position == 0 and piece.shape[depth][row][column] == ACTIVE_PIECE_VALUE then
                    board[piece.position.z + depth][piece.position.y + row][piece.position.x + column] = ACTIVE_PIECE_VALUE
                end
            end
        end
    end

    local ghost = get_ghost(board, piece)
    if ghost.position.y > piece.position.y then
        for depth = 1, #ghost.shape do
            for row = 1, #ghost.shape[depth] do
                for column = 1, #ghost.shape[depth][row] do
                    local current_position = board[ghost.position.z + depth][ghost.position.y + row][ghost.position.x + column]
                    if current_position == 0 and ghost.shape[depth][row][column] == GHOST_PIECE_VALUE then
                        board[ghost.position.z + depth][ghost.position.y + row][ghost.position.x + column] = GHOST_PIECE_VALUE
                    end
                end
            end
        end
    end
end

function clear_piece(board, piece)
    for depth = 1, #board do
        for row = 1, #board[depth] do
            for column = 1, #board[depth][row] do
                if board[depth][row][column] == ACTIVE_PIECE_VALUE or board[depth][row][column] == GHOST_PIECE_VALUE then
                    board[depth][row][column] = 0
                end
            end
        end
    end
end

function get_ghost(board, piece)
    -- Create a copy of the current piece to use as the ghost
    local ghost = {
        shape = {},
        position = {
            x = piece.position.x,
            y = piece.position.y,
            z = piece.position.z
        }
    }
    
    -- Copy the shape
    for depth = 1, #piece.shape do
        ghost.shape[depth] = {}
        for row = 1, #piece.shape[depth] do
            ghost.shape[depth][row] = {}
            for column = 1, #piece.shape[depth][row] do
                if piece.shape[depth][row][column] == ACTIVE_PIECE_VALUE then
                    ghost.shape[depth][row][column] = GHOST_PIECE_VALUE
                else
                    ghost.shape[depth][row][column] = 0
                end
            end
        end
    end
    
    -- Drop the ghost piece as far down as it can go
    while true do
        ghost.position.y = ghost.position.y + 1
        
        if not is_valid_position(board, ghost) then
            ghost.position.y = ghost.position.y - 1
            break
        end
    end
    
    return ghost
end

function piece_by_id(id)
    if id == 1 then
        piece = new_T_PIECE()
    elseif id == 2 then
        piece = new_J_PIECE()
    elseif id == 3 then
        piece = new_Z_PIECE()
    elseif id == 4 then
        piece = new_O_PIECE()
    elseif id == 5 then
        piece = new_S_PIECE()
    elseif id == 6 then
        piece = new_L_PIECE()
    elseif id == 7 then
        piece = new_I_PIECE()
    end

    return piece
end

function new_piece()
    -- Debug
    -- current_piece = new_DEBUG_PIECE()
    -- current_piece = new_I_PIECE()
    -- current_piece = new_Z_PIECE()

    current_piece = next_piece
    next_piece = piece_by_id(math.random(7))

    set_piece(board, current_piece)
end

function is_valid_position(board, piece)
    for depth = 1, #piece.shape do
        for row = 1, #piece.shape[depth] do
            for column = 1, #piece.shape[depth][row] do
                if piece.shape[depth][row][column] == ACTIVE_PIECE_VALUE or 
                piece.shape[depth][row][column] == GHOST_PIECE_VALUE then
                    local board_x = piece.position.x + column
                    local board_y = piece.position.y + row
                    local board_z = piece.position.z + depth

                    -- Check for horizontal bounds
                    if board_x > COLUMNS + COLUMN_BUFFER - COLUMN_OFFSET or 
                    board_x <= COLUMN_BUFFER - COLUMN_OFFSET then
                        return false
                    end

                    -- Check for vertical bounds
                    if board_y > ROWS + ROW_BUFFER - ROW_OFFSET then
                        return false
                    end

                    -- Check for depth bounds
                    if board_z > DEPTH + DEPTH_BUFFER - DEPTH_OFFSET or
                    board_z < DEPTH_OFFSET then
                        return false
                    end
                    
                    -- Check for collision with placed pieces
                    if board[board_z][board_y][board_x] == PLACED_PIECE_VALUE then
                        return false
                    end
                end
            end
        end
    end

    return true
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

function shift_piece2D(board, piece, dir)
    clear_piece(board, piece)

    local original_x = piece.position.x
    piece.position.x = piece.position.x + dir

    if not is_valid_position(board, piece) then
        piece.position.x = original_x
    end

    set_piece(board, piece)
end

function shift_piece3D(board, piece, dir)
    clear_piece(board, piece)

    local original_z = piece.position.z
    piece.position.z = piece.position.z + dir

    if not is_valid_position(board, piece) then
        piece.position.z = original_z
    end

    set_piece(board, piece)
end

function rotate_piece(board, piece, dir)
    -- Create an empty shape with same dimensions
    local rotated_shape = {}
    for depth = 1, #piece.shape do 
        rotated_shape[depth] = {}
        for row = 1, #piece.shape[depth] do
            rotated_shape[depth][row] = {}
            for column = 1, #piece.shape[depth][row] do
                rotated_shape[depth][row][column] = 0
            end
        end
    end

    -- Z_PIECE example
    -- {0, 0, 0}, | {0, 0, 0}, | {0, 0, 0},
    -- {0, 0, 0}, | {0, 1, 1}, | {1, 1, 0},
    -- {0, 0, 0}, | {0, 0, 0}, | {0, 0, 0},
    -- after rotating clockwise
    -- {0, 0, 0}, | {0, 0, 0}, | {0, 1, 0},
    -- {0, 0, 0}, | {0, 1, 0}, | {0, 1, 0},
    -- {0, 0, 0}, | {1, 1, 0}, | {0, 0, 0},
    
    -- Process each depth layer separately
    for depth = 1, #piece.shape do
        -- Rotate this depth layer
        for row = 1, #piece.shape[depth] do
            for column = 1, #piece.shape[depth][row] do
                if dir == 1 then -- Clockwise
                    rotated_shape[depth][column][#piece.shape - row + 1] = piece.shape[depth][row][column]
                else -- Counter-clockwise
                    rotated_shape[depth][#piece.shape - column + 1][row] = piece.shape[depth][row][column]
                end
            end
        end
    end
    
    -- Store original shape and position in case rotation is invalid
    local original_shape = piece.shape
    local original_x = piece.position.x
    
    -- Apply the rotation
    piece.shape = rotated_shape
    
    -- Check if the rotation is valid
    if not is_valid_position(board, piece) then
        local shift_success = false
        
        -- Try wall kicks
        local kicks = {-1, 1, -2, 2}
        for _, kick in ipairs(kicks) do
            piece.position.x = original_x + kick
            if is_valid_position(board, piece) then
                shift_success = true
                break
            end
        end
        
        -- If no valid position found, revert rotation
        if not shift_success then
            piece.shape = original_shape
            piece.position.x = original_x
        end
    end
    
    -- Clear and redraw board with rotated piece
    clear_piece(board, piece)
    set_piece(board, piece)
end


function twist_piece(board, piece, dir)
    -- Create a new table for the twisted shape
    local twisted_shape = {}

    -- Initialize empty twisted shape with the same dimensions as the original
    for depth = 1, #piece.shape do 
        twisted_shape[depth] = {}
        for row = 1, #piece.shape[depth] do
            twisted_shape[depth][row] = {}
            for column = 1, #piece.shape[depth][row] do
                twisted_shape[depth][row][column] = 0
            end
        end
    end

    -- Z_PIECE example
    -- {0, 0, 0}, | {1, 1, 0}, | {0, 0, 0},
    -- {0, 0, 0}, | {0, 1, 1}, | {0, 0, 0},
    -- {0, 0, 0}, | {0, 0, 0}, | {0, 0, 0},
    -- after twisting clockwise 
    -- {0, 1, 0}, | {0, 1, 0}, | {0, 0, 0},
    -- {0, 0, 0}, | {0, 1, 0}, | {0, 1, 0},
    -- {0, 0, 0}, | {0, 0, 0}, | {0, 0, 0},
    -- after twisting clockwise again
    -- {0, 0, 0}, | {0, 1, 1}, | {0, 0, 0},
    -- {0, 0, 0}, | {1, 1, 0}, | {0, 0, 0},
    -- {0, 0, 0}, | {0, 0, 0}, | {0, 0, 0},

    for row = 1, #piece.shape[1] do
        -- Rotate this row across all depths
        for depth = 1, #piece.shape do
            for column = 1, #piece.shape[depth][row] do
                if dir == 1 then -- Clockwise around Y axis
                    twisted_shape[column][row][#piece.shape - depth + 1] = piece.shape[depth][row][column]
                else -- Counter-clockwise around Y axis
                    twisted_shape[#piece.shape - column + 1][row][depth] = piece.shape[depth][row][column]
                end
            end
        end
    end

    -- Store the original shape in case we need to revert
    local original_shape = piece.shape
    piece.shape = twisted_shape

    local original_z = piece.position.z

    -- Check if the twist is valid in current position
    if not is_valid_position(board, piece) then
        local shift_success = false
        
        -- Try different depth kicks (offsets)
        local kicks = {-1, 1, -2, 2}  -- Try closer offsets first
        
        for _, kick in ipairs(kicks) do
            -- Apply the kick offset
            piece.position.z = original_z + kick
            
            -- Check if this position is valid
            if is_valid_position(board, piece) then
                shift_success = true
                break
            end
        end
        
        -- If no valid position was found, revert twist
        if not shift_success then
            piece.shape = original_shape
            piece.position.z = original_z
        end
    end

    -- Clear and redraw board with twisted piece
    clear_piece(board, piece)
    set_piece(board, piece)
end

function tilt_piece(board, piece, dir)
    -- Create an empty shape with same dimensions
    local tilted_shape = {}
    for depth = 1, #piece.shape do 
        tilted_shape[depth] = {}
        for row = 1, #piece.shape[depth] do
            tilted_shape[depth][row] = {}
            for column = 1, #piece.shape[depth][row] do
                tilted_shape[depth][row][column] = 0
            end
        end
    end

    -- Z_PIECE example
    -- {0, 0, 0}, | {1, 1, 0}, | {0, 0, 0},
    -- {0, 0, 0}, | {0, 1, 1}, | {0, 0, 0},
    -- {0, 0, 0}, | {0, 0, 0}, | {0, 0, 0},
    -- after tilting clockwise 
    -- {0, 0, 0}, | {0, 0, 0}, | {0, 0, 0},
    -- {0, 0, 0}, | {0, 1, 1}, | {1, 1, 0},
    -- {0, 0, 0}, | {0, 0, 0}, | {0, 0, 0},
    -- after twisting clockwise again
    -- {0, 0, 0}, | {0, 0, 0}, | {0, 0, 0},
    -- {0, 0, 0}, | {0, 1, 1}, | {0, 0, 0},
    -- {0, 0, 0}, | {1, 1, 0}, | {0, 0, 0},
    
    for column = 1, #piece.shape[1][1] do
        -- Rotate this column across all depths and rows
        for depth = 1, #piece.shape do
            for row = 1, #piece.shape[depth] do
                if dir == 1 then -- Forward tilt (clockwise in depth-row plane)
                    tilted_shape[row][#piece.shape - depth + 1][column] = piece.shape[depth][row][column]
                else -- Backward tilt (counter-clockwise in depth-row plane)
                    tilted_shape[#piece.shape - row + 1][depth][column] = piece.shape[depth][row][column]
                end
            end
        end
    end
    
    -- Store the original shape in case we need to revert
    local original_shape = piece.shape
    piece.shape = tilted_shape
    
    -- Store original position in case tilt is invalid
    local original_z = piece.position.z
    local original_y = piece.position.y
    
    -- Check if the tilt is valid in current position
    if not is_valid_position(board, piece) then
        local shift_success = false
        
        -- Try different z-axis kicks first (depth)
        local z_kicks = {-1, 1, -2, 2}
        for _, z_kick in ipairs(z_kicks) do
            piece.position.z = original_z + z_kick
            if is_valid_position(board, piece) then
                shift_success = true
                break
            end
        end
        
        -- If z-kicks didn't work, try y-axis kicks (height)
        if not shift_success then
            piece.position.z = original_z  -- Reset z position
            
            local y_kicks = {-1, 1, -2, 2}
            for _, y_kick in ipairs(y_kicks) do
                piece.position.y = original_y + y_kick
                if is_valid_position(board, piece) then
                    shift_success = true
                    break
                end
            end
        end
        
        -- If no valid position was found, revert tilt
        if not shift_success then
            piece.shape = original_shape
            piece.position.z = original_z
            piece.position.y = original_y
        end
    end
    
    -- Clear and redraw board with tilted piece
    clear_piece(board, piece)
    set_piece(board, piece)
end

function place_piece(board, piece)
    for depth = 1, #piece.shape do
        for row = 1, #piece.shape[depth] do
            for column = 1, #piece.shape[depth][row] do
                local board_x = piece.position.x + column
                local board_y = piece.position.y + row
                local board_z = piece.position.z + depth

                if board[board_z][board_y][board_x] == 0 and piece.shape[depth][row][column] == ACTIVE_PIECE_VALUE then
                    board[board_z][board_y][board_x] = PLACED_PIECE_VALUE
                end
            end
        end
    end

    line_clear(board)
    new_piece()
end

function line_clear(board)
    local line_clear_count = 0

    for row = 1, ROWS + ROW_BUFFER do
        local row_full_across_all_depths = true
        
        -- Check if this row is full across all depths
        for depth = DEPTH_OFFSET, DEPTH + DEPTH_BUFFER - DEPTH_OFFSET do
            local depth_row_full = true
            for column = COLUMN_OFFSET, COLUMNS + COLUMN_BUFFER - COLUMN_OFFSET do
                if board[depth][row][column] ~= PLACED_PIECE_VALUE then
                    depth_row_full = false
                    break
                end
            end
            
            -- If this row isn't full in any depth, then it's not full across all depths
            if not depth_row_full then
                row_full_across_all_depths = false
                break
            end
        end
        
        -- If the row is full across all depths, clear it everywhere
        if row_full_across_all_depths then
            line_clear_count = line_clear_count + 1
            
            -- Clear this row in all depths and move rows down
            for depth = DEPTH_OFFSET, DEPTH + DEPTH_BUFFER - DEPTH_OFFSET do
                -- Move all rows above this line down by one row
                for move_row = row, 2, -1 do
                    for column = 1, COLUMNS + COLUMN_BUFFER do
                        board[depth][move_row][column] = board[depth][move_row - 1][column]
                    end
                end
                
                -- Clear the top row
                for column = 1, COLUMNS + COLUMN_BUFFER do
                    board[depth][1][column] = 0
                end
            end
            
            -- Don't increment row since we need to check the same row again
            row = row - 1
        end
    end

    -- NES Tetris standard for score calculation
    if line_clear_count == 1 then
        score = score + (40 * (level + 1))
    elseif line_clear_count == 2 then
        score = score + (100 * (level + 1))
    elseif line_clear_count == 3 then
        score = score + (300 * (level + 1))
    elseif line_clear_count == 4 then
        score = score + (1200 * (level + 1)) -- Boom! Tetris!
    end

    if score > high_score then
        high_score = score
        love.filesystem.write(high_score_file, tostring(high_score))
    end
end



function love.keypressed(key)
    -- Debug
    if love.keyboard.isDown("s", "down") then
        lower_piece(board, current_piece)
    end

    if key == "a" or key == "left" then
        shift_piece2D(board, current_piece, -1)
    elseif key == "d" or key == "right" then
        shift_piece2D(board, current_piece, 1)
    elseif key == "space" then
        shift_piece3D(board, current_piece, 1)
    elseif key == "lshift" then
        shift_piece3D(board, current_piece, -1)
    elseif key == "q" then
        rotate_piece(board, current_piece, -1)
    elseif key == "e" then
        rotate_piece(board, current_piece, 1)
    elseif key == "z" then
        twist_piece(board, current_piece, -1)
    elseif key == "c" then
        twist_piece(board, current_piece, 1)
    elseif key == "r" then
        tilt_piece(board, current_piece, 1)
    elseif key == "f" then
        tilt_piece(board, current_piece, -1)
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