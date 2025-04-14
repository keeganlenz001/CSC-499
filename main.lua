
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

PADDING = GRID

BOARD_WIDTH = COLUMNS * GRID
BOARD_HEIGHT = ROWS * GRID

INFO_PANEL = 14
CONTROL_PANEL = 34
FONT_SIZE = 8

CANVAS_WIDTH = (BOARD_WIDTH * DEPTH) + (PADDING * (DEPTH + 1))
CANVAS_HEIGHT = (BOARD_HEIGHT) + (PADDING * 2) + (INFO_PANEL + PADDING) + (CONTROL_PANEL + PADDING)
ASPECT_RATIO = 16/9
    
love.window.setMode(CANVAS_WIDTH * 3, CANVAS_HEIGHT * 3, {resizable=true})
-- love.window.setMode(CANVAS_WIDTH, CANVAS_HEIGHT, {resizable=true})

ACTIVE_PIECE_VALUES = {1, 2, 3}
PLACED_PIECE_VALUES = {4, 5, 6}
GHOST_PIECE_VALUE = 7

RGB = 0.00392156862

NES_CYAN = {0, 0.8, 0.8, 1}
NES_DARK_BLUE = {0, 0.2, 0.4, 1}

PIECE_COLOR_SETS = {
    {
        {99 * RGB, 173 * RGB, 255 * RGB}, -- Light
        {66 * RGB, 66 * RGB, 255 * RGB} -- Dark
    },
    {
        {140 * RGB, 214 * RGB, 0},
        {16 * RGB, 148 * RGB, 0}
    },
    {
        {239 * RGB, 107 * RGB, 255 * RGB},
        {156 * RGB, 24 * RGB, 206 * RGB}
    },
    {
        {66 * RGB, 66 * RGB, 255 * RGB},
        {90 * RGB, 231 * RGB, 49 * RGB},
    },
    {
        {181 * RGB, 33 * RGB, 123 * RGB},
        {66 * RGB, 222 * RGB, 132 * RGB}
    },
    {
        {66 * RGB, 222 * RGB, 132 * RGB},
        {148 * RGB, 148 * RGB, 255 * RGB}
    },
    {
        {160 * RGB, 35 * RGB, 30 * RGB},
        {80 * RGB, 80 * RGB, 80 * RGB}
    },
    {
        {115 * RGB, 41 * RGB, 255 * RGB},
        {107 * RGB, 0 * RGB, 66 * RGB}
    },
    {
        {66 * RGB, 66 * RGB, 255 * RGB},
        {181 * RGB, 49 * RGB, 33 * RGB}
    },
    {
        {181 * RGB, 49 * RGB, 33 * RGB},
        {231 * RGB, 156 * RGB, 33 * RGB}
    }
}

PIXEL = 1
PIECE_SPRITES = {
    { -- Hollow
        {x = 0, y = 0, w = GRID, h = GRID}, -- Fill black
        {x = 0, y = 0, w = GRID - PIXEL, h = GRID - PIXEL}, -- Fill dark
        {x = PIXEL, y = PIXEL, w = GRID - (3 * PIXEL), h = GRID - (3 * PIXEL)}, -- Fill white
        {x = 0, y = 0, w = PIXEL, h = PIXEL} -- Fill white
    },

    { -- Light
        {x = 0, y = 0, w = GRID, h = GRID}, -- Fill black
        {x = 0, y = 0, w = GRID - PIXEL, h = GRID - PIXEL}, -- Fill light
        {x = PIXEL, y = PIXEL, w = 2 * PIXEL, h = PIXEL}, -- Fill white
        {x = PIXEL, y = 2 * PIXEL, w = PIXEL, h = PIXEL}, -- Fill white
        {x = 0, y = 0, w = PIXEL, h = PIXEL} -- Fill white
    },

    { -- Dark
        {x = 0, y = 0, w = GRID, h = GRID}, -- Fill black
        {x = 0, y = 0, w = GRID - PIXEL, h = GRID - PIXEL}, -- Fill dark
        {x = PIXEL, y = PIXEL, w = 2 * PIXEL, h = PIXEL}, -- Fill white
        {x = PIXEL, y = 2 * PIXEL, w = PIXEL, h = PIXEL}, -- Fill white
        {x = 0, y = 0, w = PIXEL, h = PIXEL} -- Fill white
    },

    { -- Ghost
        {x = 0, y = 0, w = GRID, h = GRID}, -- Fill black
        {x = 0, y = 0, w = GRID - PIXEL, h = GRID - PIXEL}, -- Fill white
        {x = PIXEL, y = PIXEL, w = GRID - (3 * PIXEL), h = GRID - (3 * PIXEL)}, -- Fill black
    }
}

function love.load()
    canvas = love.graphics.newCanvas(CANVAS_WIDTH, CANVAS_HEIGHT)
    canvas:setFilter("nearest", "nearest")

    high_score_file = "high_score.txt"
    if not love.filesystem.getInfo(high_score_file) then
        love.filesystem.write(high_score_file, "0")
    end

    fall_tick = 0
    shift_tick = 0
    shift_buffer_tick = 0
    game_over_tick = 0

    level = 0
    total_lines_cleared = 0
    score = 0
    high_score = tonumber(love.filesystem.read(high_score_file), 10) or 0
    game_over = false
    game_over_time = nil
    game_over_row = 0

    screen = 0

    nes_font = love.graphics.newFont("nintendo-nes-font.ttf", FONT_SIZE)
    nes_font:setFilter("nearest", "nearest")

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
            {3, 3, 3},
            {0, 0, 3},
        }

        return {
            shape = get_shape3D(shape),
            position = {x = 5, y = 0, z = math.ceil(DEPTH / 2) - 1}
        }
    end

    function new_Z_PIECE()
        local shape = {
            {0, 0, 0},
            {2, 2, 0},
            {0, 2, 2}

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
            {0, 3, 3},
            {3, 3, 0}
        }

        return {
            shape = get_shape3D(shape),
            position = {x = 5, y = 0, z = math.ceil(DEPTH / 2)  - 1}
        }
    end

    function new_L_PIECE()
        local shape = {
            {0, 0, 0},
            {2, 2, 2},
            {2, 0, 0}
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

    -- next_piece = piece_by_id(math.random(7))
    -- new_piece()
end

function new_game()
    fall_tick = 0
    shift_tick = 0
    game_over_tick = 0

    level = 0
    total_lines_cleared = 0
    score = 0
    high_score = tonumber(love.filesystem.read(high_score_file), 10) or 0
    game_over = false
    game_over_time = nil
    game_over_row = 0

    for depth = 1, #board do
        for row = 1, #board[depth] do
            for column = 1, #board[depth] do
                board[depth][row][column] = 0
            end
        end
    end
    
    next_piece = piece_by_id(math.random(7))
    new_piece()
end

function set_canvas(canvas, offset_x, offset_y, scale)
    -- Reset canvas target
    love.graphics.setCanvas()

    -- Draw canvas to screen with proper scaling
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, offset_x, offset_y, 0, scale, scale)
end

function contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function draw_piece(x, y, piece_type)
    -- Get the sprite data for this piece type
    sprite = PIECE_SPRITES[piece_type]
    
    if piece_type ~= 4 then
        -- First rectangle (black background)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", x + sprite[1].x, y + sprite[1].y, sprite[1].w, sprite[1].h)
        
        -- Second rectangle (main color fill)
        if piece_type == 1 or piece_type == 3 then
            love.graphics.setColor(PIECE_COLORS[2])
        else
            love.graphics.setColor(PIECE_COLORS[1])
        end
        love.graphics.rectangle("fill", x + sprite[2].x, y + sprite[2].y, sprite[2].w, sprite[2].h)
        
        -- Remaining rectangles (white highlights)
        love.graphics.setColor(1, 1, 1)
        for i = 3, #sprite do
            love.graphics.rectangle("fill", x + sprite[i].x, y + sprite[i].y, sprite[i].w, sprite[i].h)
        end
    else
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", x + sprite[1].x, y + sprite[1].y, sprite[1].w, sprite[1].h)
        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.rectangle("fill", x + sprite[2].x, y + sprite[2].y, sprite[2].w, sprite[2].h)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", x + sprite[3].x, y + sprite[3].y, sprite[3].w, sprite[3].h)
    end
end

function get_scale_and_offset()
    local window_width, window_height = love.graphics.getDimensions()
    local window_aspect = window_width / window_height
    local scale_factor, offset_x, offset_y
    
    if window_aspect > ASPECT_RATIO then
        -- Window is wider than target ratio (letterboxing on sides)
        scale_factor = window_height / CANVAS_HEIGHT
        offset_x = (window_width - (CANVAS_WIDTH * scale_factor)) / 2
        offset_y = 0
    else
        -- Window is taller than target ratio (letterboxing on top/bottom)
        scale_factor = window_width / CANVAS_WIDTH
        offset_x = 0
        offset_y = (window_height - (CANVAS_HEIGHT * scale_factor)) / 2
    end
    
    return scale_factor, offset_x, offset_y
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setLineStyle("rough")

    local scale, offset_x, offset_y = get_scale_and_offset()

    love.graphics.setColor(1, 1, 1, 1) -- White text
    love.graphics.setFont(nes_font)

    if screen == 0 then
        center_x = canvas:getWidth() / 2
        center_y = canvas:getHeight() / 2
        button_width = PADDING * 8
        button_height = PADDING * 2
    
        buttons = {
            {center_x - (button_width / 2), (center_y + (PADDING  * 4)) - (button_height / 2), button_width, button_height, "START"},
            {center_x - (button_width / 2), (center_y + (PADDING  * 4)) + (button_height / 2) + PADDING, button_width, button_height, "OPTIONS"},
            {center_x - (button_width / 2), (center_y + (PADDING  * 4)) + (button_height * 2) + PADDING, button_width, button_height, "QUIT"}
        }

        for i = 1, #buttons do
            love.graphics.rectangle("line", buttons[i][1], buttons[i][2], buttons[i][3], buttons[i][4])
            love.graphics.printf(buttons[i][5], buttons[i][1], buttons[i][2] + (buttons[i][4] / 2) - (nes_font:getHeight() / 2), button_width, "center")
        end

        set_canvas(canvas, offset_x, offset_y, scale)

        return
    end

    -- High Score
    formatted_top = string.format("%06d", high_score)
    love.graphics.print("TOP", PADDING, PADDING / 2)
    love.graphics.print(formatted_top, PADDING, (PADDING / 2) + FONT_SIZE)

    -- Score
    formatted_score = string.format("%06d", score)
    love.graphics.print("SCORE", PADDING * 12, PADDING / 2)
    love.graphics.print(formatted_score, PADDING * 12, (PADDING / 2) + FONT_SIZE)

    -- Next Piece
    PIECE_COLORS = PIECE_COLOR_SETS[(level % 10) + 1]

    love.graphics.print("NEXT", PADDING * 23, PADDING / 2)
    for depth = 1, #next_piece.shape do
        local x_offset = PADDING * 29
        local y_offset = PADDING / 2

        for row = 1, #next_piece.shape[depth] do
            for column = 1, #next_piece.shape[depth][row] do
                local x = x_offset + ((column - COLUMN_OFFSET) * GRID)
                local y = y_offset + ((row - ROW_OFFSET) * GRID)

                if contains(ACTIVE_PIECE_VALUES, next_piece.shape[depth][row][column]) then
                    if next_piece.shape[depth][row][column] == ACTIVE_PIECE_VALUES[1] then
                        draw_piece(x, y, 1, PIXEL)
                    elseif next_piece.shape[depth][row][column] == ACTIVE_PIECE_VALUES[2] then
                        draw_piece(x, y, 2, PIXEL)
                    elseif next_piece.shape[depth][row][column] == ACTIVE_PIECE_VALUES[3] then
                        draw_piece(x, y, 3, PIXEL)
                    end
                end
            end
        end
    end

    -- Level
    formatted_level = string.format("%02d", level)
    love.graphics.print("LEVEL", PADDING * 34, PADDING / 2)
    love.graphics.print(formatted_level, (PADDING * 34) + (FONT_SIZE * 2), (PADDING / 2) + FONT_SIZE)

    -- Draw boards
    for depth = 1, DEPTH do
        local x_offset = (depth - 1) * (COLUMNS * GRID + PADDING) + PADDING
        local y_offset = PADDING + INFO_PANEL
        local x = x_offset
        local y = y_offset

        love.graphics.setColor(NES_CYAN)
        love.graphics.rectangle("fill", x - PIXEL, y + PIXEL, (COLUMNS * GRID) + (PIXEL * 2), (ROWS * GRID + (PIXEL * 2)))

        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", x, y + (PIXEL * 2), COLUMNS * GRID, ROWS * GRID)
    end

    -- Draw blocks
    for depth = 1, #board do
        local x_offset = (depth - DEPTH_OFFSET) * (COLUMNS * GRID + PADDING) + PADDING
        local y_offset = INFO_PANEL + PADDING
            
        for row = 1, #board[depth] do
            for column = 1, #board[depth][row] do
                local x = x_offset + ((column - COLUMN_OFFSET) * GRID)
                local y = y_offset + ((row - ROW_OFFSET) * GRID) + (PIXEL * 2)

                if contains(ACTIVE_PIECE_VALUES, board[depth][row][column]) and row >= ROW_OFFSET then
                    if board[depth][row][column] == ACTIVE_PIECE_VALUES[1] then
                        draw_piece(x, y, 1, PIXEL)
                    elseif board[depth][row][column] == ACTIVE_PIECE_VALUES[2] then
                        draw_piece(x, y, 2, PIXEL)
                    elseif board[depth][row][column] == ACTIVE_PIECE_VALUES[3] then
                        draw_piece(x, y, 3, PIXEL)
                    end
                elseif board[depth][row][column] == GHOST_PIECE_VALUE and row >= ROW_OFFSET then
                    draw_piece(x, y, 4, PIXEL)
                elseif contains(PLACED_PIECE_VALUES, board[depth][row][column]) and row >= ROW_OFFSET then
                    if board[depth][row][column] == PLACED_PIECE_VALUES[1] then
                        draw_piece(x, y, 1, PIXEL)
                    elseif board[depth][row][column] == PLACED_PIECE_VALUES[2] then
                        draw_piece(x, y, 2, PIXEL)
                    elseif board[depth][row][column] == PLACED_PIECE_VALUES[3] then
                        draw_piece(x, y, 3, PIXEL)
                    end
                end
            end
        end
    end
    
    if game_over then
        for depth = 1, #board do
            local x_offset = (depth - DEPTH_OFFSET) * (COLUMNS * GRID + PADDING) + PADDING
            local y_offset = INFO_PANEL + PADDING
            
            for row = 1, math.min(game_over_row, #board[depth] - ROW_BUFFER) do
                local x = x_offset + PIXEL
                local y = y_offset + ((row - 1) * GRID) + (PIXEL * 2)

                love.graphics.setColor(PIECE_COLORS[2])
                love.graphics.rectangle("fill", x, y, (COLUMNS * GRID) - PIXEL, PIXEL * 2)
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("fill", x, y + (PIXEL * 2), (COLUMNS * GRID) - PIXEL, PIXEL * 3)
                love.graphics.setColor(PIECE_COLORS[1])
                love.graphics.rectangle("fill", x, y + (PIXEL * 5), (COLUMNS * GRID) - PIXEL, PIXEL * 2)
                love.graphics.setColor(0, 0, 0)
                love.graphics.rectangle("fill", x, y + (PIXEL * 7), (COLUMNS * GRID) - PIXEL, PIXEL)
            end
        end
    end

    love.graphics.setColor(1, 1, 1)
    controls_base_y = INFO_PANEL + PADDING + (PADDING / 2) + BOARD_HEIGHT + (PIXEL * 2)

    love.graphics.print("MOVEMENT", PADDING * 7 + (PADDING / 2), controls_base_y)
    love.graphics.print("HORIZONTAL:A,D", PADDING * 4 + (PADDING / 2), controls_base_y + FONT_SIZE + (FONT_SIZE / 2))
    love.graphics.print("DEPTH:SPACE,LSHIFT", PADDING * 2 + (PADDING / 2), controls_base_y + (FONT_SIZE * 3))
    love.graphics.print("DOWN:S", PADDING * 8 + (PADDING / 2), controls_base_y + (FONT_SIZE * 4) + (FONT_SIZE / 2))

    love.graphics.print("ROTATION", PADDING * 29 + (PADDING / 2), controls_base_y)
    love.graphics.print("ROTATE:Q,E", PADDING * 28 + (PADDING / 2), controls_base_y + FONT_SIZE + (FONT_SIZE / 2))
    love.graphics.print("TWIST:C,Z", PADDING * 29, controls_base_y + (FONT_SIZE * 3))
    love.graphics.print("TILT:R,F", PADDING * 29 + (PADDING / 2), controls_base_y + (FONT_SIZE * 4) + (FONT_SIZE / 2))

    set_canvas(canvas, offset_x, offset_y, scale)

    -- love.graphics.setColor(1, 0, 0)
    -- grid = GRID * 3
    -- for i = 0, love.graphics.getWidth() / grid do
    --     love.graphics.line(i * grid, 0, i * grid, love.graphics.getHeight())
    --     -- love.graphics.line(i * (grid + 1), 0, i * (grid + 1), love.graphics.getHeight())
    --     -- love.graphics.line((i * grid) - 0.5, 0, (i * grid) - 0.5, love.graphics.getHeight())
    -- end

    -- for i = 0, love.graphics.getHeight() / grid  do
    --     love.graphics.line(0, i * grid, love.graphics.getWidth(), i * grid)
    --     -- love.graphics.line(0, (i * grid) - 0.5, love.graphics.getWidth(), (i * grid) - 0.5)
    --     -- love.graphics.line(0, (i * (grid + 1)) - 0.5, love.graphics.getWidth(), (i * (grid + 1)) - 0.5)
    -- end
end

function set_piece(board, piece)
    for depth = 1, #piece.shape do
        for row = 1, #piece.shape[depth] do
            for column = 1, #piece.shape[depth][row] do
                local current_position = board[piece.position.z + depth][piece.position.y + row][piece.position.x + column]
                if current_position == 0 and contains(ACTIVE_PIECE_VALUES, piece.shape[depth][row][column]) then
                    board[piece.position.z + depth][piece.position.y + row][piece.position.x + column] = piece.shape[depth][row][column]
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
                if contains(ACTIVE_PIECE_VALUES, board[depth][row][column]) or board[depth][row][column] == GHOST_PIECE_VALUE then
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
                if contains(ACTIVE_PIECE_VALUES, piece.shape[depth][row][column]) then
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

    if not is_valid_position(board, current_piece) then
        -- current_piece.position.y = current_piece.position.y - 1
        -- if not is_valid_position(board, current_piece) then
        --     current_piece.position.y = current_piece.position.y + 1
        --     game_over = true
        --     return
        -- end

        game_over = true
        return
    end

    set_piece(board, current_piece)
end

function is_valid_position(board, piece)
    for depth = 1, #piece.shape do
        for row = 1, #piece.shape[depth] do
            for column = 1, #piece.shape[depth][row] do
                if contains(ACTIVE_PIECE_VALUES, piece.shape[depth][row][column]) or 
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
                    if contains(PLACED_PIECE_VALUES, board[board_z][board_y][board_x]) then
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

                if board[board_z][board_y][board_x] == 0 and contains(ACTIVE_PIECE_VALUES, piece.shape[depth][row][column]) then
                    if piece.shape[depth][row][column] == ACTIVE_PIECE_VALUES[1] then
                        board[board_z][board_y][board_x] = PLACED_PIECE_VALUES[1]
                    elseif piece.shape[depth][row][column] == ACTIVE_PIECE_VALUES[2] then
                        board[board_z][board_y][board_x] = PLACED_PIECE_VALUES[2]
                    elseif piece.shape[depth][row][column] == ACTIVE_PIECE_VALUES[3] then
                        board[board_z][board_y][board_x] = PLACED_PIECE_VALUES[3]
                    end
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
                if not contains(PLACED_PIECE_VALUES, board[depth][row][column]) then
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

    total_lines_cleared = total_lines_cleared + (line_clear_count * 4)
    level = math.floor(total_lines_cleared / 10)
    -- level = math.floor(total_lines_cleared / 1)

    -- NES Tetris standard for score calculation (multiplied by depth)
    if line_clear_count == 1 then
        score = score + (40 * (level + 1) * DEPTH)
    elseif line_clear_count == 2 then
        score = score + (100 * (level + 1) * DEPTH)
    elseif line_clear_count == 3 then
        score = score + (300 * (level + 1) * DEPTH)
    elseif line_clear_count == 4 then
        score = score + (1200 * (level + 1) * DEPTH) -- Boom! Tetris!
    end

    if score > high_score then
        high_score = score
        love.filesystem.write(high_score_file, tostring(high_score))
    end
end



function love.keypressed(key)
    if game_over then
        return
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
    if screen == 0 then
        return
    end

    fall_tick = fall_tick + dt

    if level < 15 then
        local drop_rates = {
            0.01667, 0.021017, 0.026977, 0.035256, 0.04693,
            0.06361, 0.0879, 0.1236, 0.1775, 0.2598,
            0.388, 0.59, 0.92, 1.46, 2.36
        }
        fall_rate = drop_rates[level + 1]
    else
        local base = 2.36
        local multiplier = 1.5
        fall_rate = base * (multiplier ^ (level - 15))
    end

    fall_interval = 1 / (fall_rate * 60)

    if fall_tick > fall_interval then
        fall_tick = 0
        lower_piece(board, current_piece)
    end

    if love.keyboard.isDown("s", "down") and fall_tick > 0.025 and not game_over then
        fall_tick = 0
        lower_piece(board, current_piece)
    end

    if not love.keyboard.isDown("a", "left") then shift_buffer_tick_left = 0 end
    if not love.keyboard.isDown("d", "right") then shift_buffer_tick_right = 0 end

    if love.keyboard.isDown("a", "left") and not game_over then
        shift_buffer_tick_left = shift_buffer_tick_left + dt
        shift_buffer_tick_right = 0
        if shift_buffer_tick_left > 0.2 then
            shift_tick = shift_tick + dt
            if shift_tick > 0.05 then
                shift_tick = 0
                shift_piece2D(board, current_piece, -1)
            end
        end
    elseif love.keyboard.isDown("d", "right") and not game_over then
        shift_buffer_tick_right = shift_buffer_tick_right + dt
        shift_buffer_tick_left = 0
        if shift_buffer_tick_right > 0.2 then
            shift_tick = shift_tick + dt
            if shift_tick > 0.05 then
                shift_tick = 0
                shift_piece2D(board, current_piece, 1)
            end
        end
    end

    if game_over then
        game_over_tick = game_over_tick + dt
        
        if game_over_tick > 0.1 then
            game_over_tick = 0
            game_over_row = game_over_row + 1  -- Move to next row
        end

        if game_over_row > 30 then -- Arbitrary wait time
            new_game()
        end
    end
end