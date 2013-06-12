require 'collision'

-- CONFIG
local HEXAGON_RADIUS = 25.0;
local NUM_ROWS = 10;
local NUM_COLUMNS = 7;
local GRID_OFFSET = 100;

-- INTERNAL CONSTANTS
local HEXAGON_POINTS = {};
local HEXAGON_NUM_SIDES = 6;
local HEXAGON_RADIANS_PER_SIDE = math.pi * 2 / HEXAGON_NUM_SIDES;

-- GAME STATE
local player_x = 1;
local player_y = 1;
local cone_angle = math.rad(90.0); -- Radians
local cone_distance = 200.0; -- Pixels
local cone_size = math.rad(30.0); -- Radians

function love.load()
	for i = 1, 8 do
		local x = HEXAGON_RADIUS * math.sin(i * HEXAGON_RADIANS_PER_SIDE);
		table.insert(HEXAGON_POINTS, x);
		local y = HEXAGON_RADIUS * math.cos(i * HEXAGON_RADIANS_PER_SIDE);
		table.insert(HEXAGON_POINTS, y);
	end
	love.graphics.setBackgroundColor(90, 90, 90);
	love.graphics.setLineWidth(2);
end

local function getHexagonWorldLocation(row, column)
	-- Source: http://www.gamedev.net/page/resources/_/technical/game-programming/coordinates-in-hexagon-based-tile-maps-r1800
	local s = HEXAGON_RADIUS;
	local h = math.sin(math.rad(30)) * s;
	local r = math.cos(math.rad(30)) * s;
	-- Returns value based on the origin (center in our case).
	return GRID_OFFSET + row * 2 * r + (column % 2 == 0 and r or 0), GRID_OFFSET + column * (h + s);
end

function love.mousepressed(x, y, btn)
	if (btn ~= 'l') then return; end
	for row = 1, NUM_ROWS do
		for column = 1, NUM_COLUMNS do
			local offsX, offsY = getHexagonWorldLocation(row, column);
			-- Do a quick sweep using a bounding box.
			if (x > offsX - HEXAGON_RADIUS and x < offsX + HEXAGON_RADIUS and y > offsY - HEXAGON_RADIUS and y < offsY + HEXAGON_RADIUS) then
				-- In practice this is where we should check vertex by vertex for the
				-- qualifying bounding box, but this is close enough for testing purposes.
				player_x = row;
				player_y = column;
				return;
			end
		end
	end
end

function love.update()
	-- Keyboard input.
	if (love.keyboard.isDown('up')) then
		cone_distance = cone_distance + 3.0;
	end
	if (love.keyboard.isDown('down')) then
		cone_distance = cone_distance - 3.0;
	end
	if (love.keyboard.isDown('left')) then
		cone_angle = cone_angle - 0.025;
	end
	if (love.keyboard.isDown('right')) then
		cone_angle = cone_angle + 0.025;
	end
	if (love.keyboard.isDown('kp+')) then
		cone_size = cone_size + 0.025;
	end
	if (love.keyboard.isDown('kp-')) then
		cone_size = cone_size - 0.025;
	end
	
	if (cone_distance < 50) then
		cone_distance = 50;
	elseif (cone_distance > 500) then
		cone_distance = 500;
	end
	
	-- I'm too lazy to hardcode these in radians lol.
	if (cone_size < math.rad(15)) then
		cone_size = math.rad(15);
	elseif (cone_size > math.rad(130)) then
		cone_size = math.rad(130);
	end
end

function love.draw()
	local player_center_x, player_center_y = getHexagonWorldLocation(player_x, player_y);
	
	-- To get a smooth cone edge you can do catmull-rom interpolation with N points of
	-- granularity, but that greatly increases complexity and execution time.
	local center_x = player_center_x + math.cos(cone_angle) * cone_distance;
	local center_y = player_center_y + math.sin(cone_angle) * cone_distance;
	local min_x = player_center_x + math.cos(cone_angle - cone_size / 2) * cone_distance;
	local min_y = player_center_y + math.sin(cone_angle - cone_size / 2) * cone_distance;
	local max_x = player_center_x + math.cos(cone_angle + cone_size / 2) * cone_distance;
	local max_y = player_center_y + math.sin(cone_angle + cone_size / 2) * cone_distance;
	
	-- Draw hex grid.
	for row = 1, NUM_ROWS do
		for column = 1, NUM_COLUMNS do
			love.graphics.push();
			local hex_x, hex_y = getHexagonWorldLocation(row, column);
			love.graphics.translate(hex_x, hex_y);
			if (row == player_x and column == player_y) then
				love.graphics.setColor(0, 255, 0);
			elseif (PointWithinShape({
						-- Order matters here, because internally lines are formed from consecutive indices to test collision.
						{x = player_center_x, y = player_center_y},
						{x = min_x, y = min_y},
						{x = center_x, y = center_y},
						{x = max_x, y = max_y}
					}, hex_x, hex_y)) then
				-- This only tests if the origin of the tile is in the cone. If you want to have a more lenient
				-- detection you can test all vertices of each hexagon for being inside the cone. Using this data
				-- you can also determine roughly how much of hex is inside the cone, allowing you to do things like
				-- modify the effect of something based on how much of the hexagon is affected.
				love.graphics.setColor(0, 0, 255);
			else
				love.graphics.setColor(255, 255, 255);
			end
			love.graphics.polygon('fill', HEXAGON_POINTS)
			love.graphics.setColor(0, 0, 0);
			love.graphics.polygon('line', HEXAGON_POINTS);
			love.graphics.pop();
		end
	end
	
	-- Draw frustum.
	love.graphics.setColor(255, 0, 0);
	love.graphics.line(player_center_x, player_center_y, min_x, min_y);
	love.graphics.line(player_center_x, player_center_y, max_x, max_y);
	
	love.graphics.setColor(255, 0, 0, 100);
	love.graphics.polygon('fill', player_center_x, player_center_y, min_x, min_y, center_x, center_y, max_x, max_y);
end