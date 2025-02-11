WIDTH = 80
HEIGHT = 160
GRID = WIDTH / 10
SCALE = 4
love.window.setMode(WIDTH * SCALE, HEIGHT * SCALE)

function love.load()

end

function love.draw()
    for i = 1, WIDTH / GRID do
        love.graphics.line(i * GRID * SCALE, 0, i * GRID * SCALE, HEIGHT * GRID * SCALE)
    end
    for i = 1, HEIGHT / GRID do
        love.graphics.line(0, i * GRID * SCALE, WIDTH * GRID * SCALE, i * GRID * SCALE)
    end
end

function love.update(dt)

end