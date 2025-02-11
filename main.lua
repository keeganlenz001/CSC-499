WIDTH = 80
HEIGHT = 160
GRID = WIDTH / 10
SCALE = 4

SCALED_GRID = GRID * SCALE

love.window.setMode(WIDTH * SCALE, HEIGHT * SCALE)

function love.load()
    tick = 0

    block = {
        x = 0,
        y = 0
    }
end

function love.draw()
    for i = 1, WIDTH / GRID do
        love.graphics.line(i * SCALED_GRID, 0, i * SCALED_GRID, HEIGHT * SCALED_GRID)
    end
    for i = 1, HEIGHT / GRID do
        love.graphics.line(0, i * SCALED_GRID, WIDTH * SCALED_GRID, i * SCALED_GRID)
    end

    love.graphics.rectangle("fill", block.x, block.y, SCALED_GRID, SCALED_GRID)
end

function love.update(dt)
    tick = tick + dt

    if tick > 1 then
        block.y = block.y + SCALED_GRID
        tick = 0
    end

    function love.keypressed(key)
        if key == "a" or key == "left" then
            if block.x - SCALED_GRID >= 0 then
                block.x = block.x - SCALED_GRID
            end
        elseif key == "d" or key == "right" then
            if block.x + SCALED_GRID < WIDTH * SCALE then
                block.x = block.x + SCALED_GRID
            end
        end
    end
end