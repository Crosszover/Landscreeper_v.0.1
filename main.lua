--[[ 
=============================================================
MÓDULO 1: CONFIGURACIÓN INICIAL Y CONSTANTES 
=============================================================
]]--

-- Configuración de la ventana
local WINDOW = {
    width = 1024,  -- Ancho basado en menu_bar.png
    height = 768   -- Altura en proporción 4:3
}

-- Configuración de tiles
local TILE_WIDTH = 64
local TILE_HEIGHT = 32
local HEIGHT_STEP = 8
local LINE_WIDTH = 1

-- Configuración del mapa
local MapSize = {width = 75, height = 75}
local HeightmapSize = {width = MapSize.width + 1, height = MapSize.height + 1}

-- Variables globales compartidas entre módulos
Heightmap = {}     -- Datos del terreno
GameObjects = {}   -- Objetos del juego
ObjectSprites = {} -- Sprites de los objetos

-- Inicializar la ventana con configuración optimizada
love.window.setMode(WINDOW.width, WINDOW.height, {
    resizable = false,
    minwidth = 1024,
    vsync = true,
    msaa = 0  -- Desactivar antialiasing para pixeles nítidos
})

function love.load()
    -- Configurar gráficos para mejor calidad de píxeles
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    love.graphics.setLineStyle("rough") -- Mejor para líneas pixeladas
    love.graphics.setBackgroundColor(0, 0, 0)
    
    -- Initialize heightmap
    for y = 1, HeightmapSize.height do
        Heightmap[y] = {}
        for x = 1, HeightmapSize.width do
            Heightmap[y][x] = 0
        end
    end
    
    -- Inicializar sistemas
    UI.load()
    Objects.init()
end
--[[ 
=============================================================
MÓDULO 2: SISTEMA DE COLORES 
=============================================================
]]--

local COLORS = {
    water = {0.2, 0.5, 0.8, 1.0},
    slope = {
        right_up = {0.5, 0.85, 0.5, 1.0},
        right_down = {0.5, 0.85, 0.5, 1.0},
        flat = {0.45, 0.75, 0.45, 1.0},
        left_up = {0.35, 0.65, 0.35, 1.0},
        left_down = {0.35, 0.65, 0.35, 1.0}
    },
    outline = {0.2, 0.2, 0.2, 0.5},
    coastline = {0.1, 0.1, 0.1, 0.8}
}


--[[ 
=============================================================
MÓDULO 3: SISTEMA DE CÁMARA 
=============================================================
]]--

local Camera = {
    x = 0,
    y = 0,
    zoom = 1,
    dragStart = nil,
    moveSpeed = 500
}

--[[ 
=============================================================
MÓDULO 4: SISTEMA DE UI 
=============================================================
]]--

local UI = {
    activeButton = nil,
    buttons = {},
    toolbarHeight = 64,    -- Altura de menu_bar.png
    buttonSize = 40,       -- Tamaño de los iconos
    images = {},           -- Almacenará todas las imágenes
    buildMenu = {
        visible = false,
        options = {
            {id = "house", name = "Casa (R para rotar)", icon = "house_right.png"},
        },
        selected = nil,
        x = 0,
        y = 0,
        width = 200,
        height = 50,       -- Reducido ya que ahora solo hay una opción
        buttonHeight = 40,
        currentRotation = "right"  -- Nueva propiedad para la rotación
    }
}

-- Carga todas las imágenes necesarias
function UI.loadImages()
    UI.images.menuBar = love.graphics.newImage("menu_bar.png")
    
    -- Definición de todos los botones y sus imágenes
    local imageFiles = {
        terrain_up = {"terrain_up.png", "terrain_up_active.png"},
        terrain_down = {"terrain_down.png", "terrain_down_active.png"},
        tree = {"tree_icon.png", "tree_icon_selected.png"},
        house = {"house_icon.png", "house_icon_selected.png"},
        destroy = {"destroy_icon.png", "destroy_icon_selected.png"}
    }
    
    -- Cargar todas las imágenes
    UI.images.buttons = {}
    for id, files in pairs(imageFiles) do
        UI.images.buttons[id] = {
            normal = love.graphics.newImage(files[1]),
            selected = love.graphics.newImage(files[2])
        }
    end
    
    -- Cargar imágenes del menú de construcción
    UI.images.buildings = {
        house_right = love.graphics.newImage("house_right.png"),
        house_left = love.graphics.newImage("house_left.png")
    }
end

function UI.load()
    UI.loadImages()
    
    -- Definir los botones con sus posiciones
    local buttonConfigs = {
        {id = "terrain_up", x = 10, tooltip = "Subir terreno"},
        {id = "terrain_down", x = 60, tooltip = "Bajar terreno"},
        {id = "tree", x = 110, tooltip = "Plantar árbol"},
        {id = "house", x = 160, tooltip = "Construir casa"},
        {id = "destroy", x = 210, tooltip = "Demoler"}
    }
    
    -- Crear los botones
    for _, config in ipairs(buttonConfigs) do
        local button = {
            id = config.id,
            x = config.x,
            y = (UI.toolbarHeight - UI.buttonSize) / 2,
            width = UI.buttonSize,
            height = UI.buttonSize,
            tooltip = config.tooltip,
            selected = false,
            hover = false
        }
        table.insert(UI.buttons, button)
    end
end

function UI.update()
    local mx, my = love.mouse.getPosition()
    
    -- Actualizar estado hover de los botones
    for _, button in ipairs(UI.buttons) do
        button.hover = mx >= button.x and mx <= button.x + button.width and
                      my >= button.y and my <= button.y + button.height
    end
    
    -- Actualizar hover del menú de construcción
    if UI.buildMenu.visible then
        local menuX, menuY = UI.buildMenu.x, UI.buildMenu.y
        for i, option in ipairs(UI.buildMenu.options) do
            local optionY = menuY + (i-1) * UI.buildMenu.buttonHeight
            option.hover = mx >= menuX and mx <= menuX + UI.buildMenu.width and
                          my >= optionY and my <= optionY + UI.buildMenu.buttonHeight
        end
    end
end

function UI.draw()
    -- Dibujar la barra de menú
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(UI.images.menuBar, 0, 0)
    
    -- Dibujar los botones
    for _, button in ipairs(UI.buttons) do
        local buttonImages = UI.images.buttons[button.id]
        local image = button.selected and buttonImages.selected or buttonImages.normal
        local alpha = button.hover and 0.8 or 1
        
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(image, button.x, button.y)
        
        -- Dibujar tooltip si el mouse está sobre el botón
        if button.hover then
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle('fill', 
                button.x, button.y + button.height + 5, 
                love.graphics.getFont():getWidth(button.tooltip) + 10, 20)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(button.tooltip, 
                button.x + 5, button.y + button.height + 5)
        end
    end
    
    -- Dibujar menú de construcción si está visible
    if UI.buildMenu.visible then
        -- Fondo del menú
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        love.graphics.rectangle('fill', 
            UI.buildMenu.x, UI.buildMenu.y, 
            UI.buildMenu.width, UI.buildMenu.height)
        
        -- Opciones del menú
        for i, option in ipairs(UI.buildMenu.options) do
            local y = UI.buildMenu.y + (i-1) * UI.buildMenu.buttonHeight
            
            -- Highlight si el mouse está encima
            if option.hover then
                love.graphics.setColor(0.3, 0.3, 0.3, 1)
                love.graphics.rectangle('fill', 
                    UI.buildMenu.x, y, 
                    UI.buildMenu.width, UI.buildMenu.buttonHeight)
            end
            
            -- Dibujar icono y nombre usando la rotación actual
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(UI.images.buildings["house_" .. UI.buildMenu.currentRotation], 
                UI.buildMenu.x + 5, 
                y + (UI.buildMenu.buttonHeight - 32) / 2, 
                0, 0.5, 0.5)
            
            love.graphics.print(option.name, 
                UI.buildMenu.x + 45, 
                y + (UI.buildMenu.buttonHeight - love.graphics.getFont():getHeight()) / 2)
        end
    end
end

function UI.mousePressed(x, y, button)
    if button == 1 then  -- Click izquierdo
        -- Primero verificar click en el menú de construcción si está visible
        if UI.buildMenu.visible then
            for i, option in ipairs(UI.buildMenu.options) do
                local optionY = UI.buildMenu.y + (i-1) * UI.buildMenu.buttonHeight
                if x >= UI.buildMenu.x and x <= UI.buildMenu.x + UI.buildMenu.width and
                   y >= optionY and y <= optionY + UI.buildMenu.buttonHeight then
                    -- Seleccionar opción de construcción
                    UI.buildMenu.selected = option.id
                    UI.buildMenu.visible = false
                    -- Mantener el botón de casa seleccionado
                    for _, btn in ipairs(UI.buttons) do
                        if btn.id == "house" then
                            btn.selected = true
                            UI.activeButton = btn
                        end
                    end
                    return true
                end
            end
            
            -- Click fuera del menú lo cierra
            UI.buildMenu.visible = false
            UI.buildMenu.selected = nil
            -- Deseleccionar botón de casa
            for _, btn in ipairs(UI.buttons) do
                if btn.id == "house" then
                    btn.selected = false
                end
            end
            UI.activeButton = nil
            return true
        end
        
        -- Verificar click en botones de la barra
        for _, btn in ipairs(UI.buttons) do
            if x >= btn.x and x <= btn.x + btn.width and
               y >= btn.y and y <= btn.y + btn.height then
                -- Si es el botón de casa, mostrar menú
                if btn.id == "house" then
                    UI.buildMenu.visible = true
                    UI.buildMenu.x = btn.x
                    UI.buildMenu.y = btn.y + btn.height + 5
                    btn.selected = true
                    UI.activeButton = btn
                else
                    -- Deseleccionar el botón anterior
                    if UI.activeButton then
                        UI.activeButton.selected = false
                    end
                    -- Seleccionar el nuevo botón
                    btn.selected = true
                    UI.activeButton = btn
                    -- Cerrar menú de construcción si estaba abierto
                    UI.buildMenu.visible = false
                    UI.buildMenu.selected = nil
                end
                return true
            end
        end
        
        -- Click fuera de la UI cierra el menú
        if UI.buildMenu.visible then
            UI.buildMenu.visible = false
            UI.buildMenu.selected = nil
            -- Deseleccionar botón de casa
            for _, btn in ipairs(UI.buttons) do
                if btn.id == "house" then
                    btn.selected = false
                end
            end
            UI.activeButton = nil
            return true
        end
    end
    return false
end

function UI.getActiveTool()
    if UI.buildMenu.selected then
        return UI.buildMenu.selected .. "_" .. UI.buildMenu.currentRotation
    end
    return UI.activeButton and UI.activeButton.id or nil
end

function UI.getToolbarHeight()
    return UI.toolbarHeight
end

-- Nueva función para rotar el edificio actual
function UI.rotateBuilding()
    if UI.buildMenu.selected == "house" or UI.activeButton and UI.activeButton.id == "house" then
        UI.buildMenu.currentRotation = UI.buildMenu.currentRotation == "right" and "left" or "right"
    end
end
--[[ 
=============================================================
MÓDULO 5: SISTEMA DE CONVERSIÓN DE COORDENADAS 
=============================================================
]]--

Coordinates = {}

function Coordinates.isoToScreen(x, y, z)
    if not x or not y or not z then return 0, 0 end
    local screenX = ((x + 0.5) - (y + 0.5)) * (TILE_WIDTH / 2) * Camera.zoom
    local screenY = ((x + 0.5) + (y + 0.5)) * (TILE_HEIGHT / 2) * Camera.zoom - z * HEIGHT_STEP * Camera.zoom
    return screenX, screenY
end

function Coordinates.screenToIso(screenX, screenY)
    -- Ajustar por la posición de la cámara y el zoom
    screenX = (screenX - love.graphics.getWidth() / 2 - Camera.x) / Camera.zoom
    screenY = (screenY - love.graphics.getHeight() / 4 - Camera.y - UI.getToolbarHeight()) / Camera.zoom
    
    -- Convertir a coordenadas isométricas
    local isoX = (screenX / (TILE_WIDTH / 2) + screenY / (TILE_HEIGHT / 2)) / 2
    local isoY = (screenY / (TILE_HEIGHT / 2) - screenX / (TILE_WIDTH / 2)) / 2
    
    -- Redondear a la posición de tile más cercana
    return math.floor(isoX + 0.5), math.floor(isoY + 0.5)
end

function Coordinates.isPointInTile(tileX, tileY, screenX, screenY)
    -- Verificar que las coordenadas son válidas
    if not (tileX and tileY and Heightmap[tileY] and Heightmap[tileY][tileX]) then
        return false
    end
    
    -- Convertir las coordenadas del tile a puntos de la pantalla
    local x1, y1 = Coordinates.isoToScreen(tileX-1, tileY-1, Heightmap[tileY][tileX])
    local x2, y2 = Coordinates.isoToScreen(tileX, tileY-1, Heightmap[tileY][tileX])
    local x3, y3 = Coordinates.isoToScreen(tileX, tileY, Heightmap[tileY][tileX])
    local x4, y4 = Coordinates.isoToScreen(tileX-1, tileY, Heightmap[tileY][tileX])
    
    -- Ajustar coordenadas por la posición de la cámara
    screenX = screenX - love.graphics.getWidth() / 2 - Camera.x
    screenY = screenY - love.graphics.getHeight() / 4 - Camera.y - UI.getToolbarHeight()
    
    -- Función auxiliar para producto cruz
    local function cross(x1, y1, x2, y2)
        return x1 * y2 - y1 * x2
    end
    
    -- Comprobar si el punto está dentro del paralelogramo usando productos cruz
    local function sameSide(px, py, ax, ay, bx, by, cx, cy)
        local b1 = cross(bx - ax, by - ay, px - ax, py - ay)
        local b2 = cross(bx - ax, by - ay, cx - ax, cy - ay)
        return (b1 < 0) == (b2 < 0)
    end
    
    -- El punto debe estar del mismo lado de todas las aristas
    return sameSide(screenX, screenY, x1, y1, x2, y2, x3, y3) and
           sameSide(screenX, screenY, x2, y2, x3, y3, x4, y4) and
           sameSide(screenX, screenY, x3, y3, x4, y4, x1, y1) and
           sameSide(screenX, screenY, x4, y4, x1, y1, x2, y2)
end
--[[ 
=============================================================
MÓDULO 6: SISTEMA DE TERRENO 
=============================================================
]]--

TerrainSystem = {
    isWaterEdge = function(h1, h2)
        return (h1 == 0 and h2 > 0) or (h1 > 0 and h2 == 0)
    end,

    getSlopeColor = function(h1, h2, h3, h4)
        h1 = h1 or 0
        h2 = h2 or 0
        h3 = h3 or 0
        h4 = h4 or 0
        
        if h1 == h2 and h2 == h3 and h3 == h4 then
            if h1 == 0 then
                return COLORS.water
            else
                return COLORS.slope.flat
            end
        end
        
        if h2 > h1 or h3 > h4 then
            if h2 > h1 then
                return COLORS.slope.right_up
            else
                return COLORS.slope.right_down
            end
        elseif h1 > h2 or h4 > h3 then
            if h1 > h2 then
                return COLORS.slope.left_up
            else
                return COLORS.slope.left_down
            end
        end
        
        return COLORS.slope.flat
    end,

    isWaterTile = function(h1, h2, h3, h4)
        return (h1 or 0) == 0 and (h2 or 0) == 0 and (h3 or 0) == 0 and (h4 or 0) == 0
    end,

    getWaterTrianglePoints = function(x1, y1, x2, y2, x3, y3, x4, y4, h1, h2, h3, h4)
        local points = {}
        if h1 == 0 then table.insert(points, {x1, y1}) end
        if h2 == 0 then table.insert(points, {x2, y2}) end
        if h3 == 0 then table.insert(points, {x3, y3}) end
        if h4 == 0 then table.insert(points, {x4, y4}) end
        return points
    end,

    autoLevel = function(x, y)
        if not Heightmap[y] or not Heightmap[y][x] then return false end
        
        local height = Heightmap[y][x]
        local changed = false
        
        local adjacentPoints = {
            {x-1, y}, {x+1, y},
            {x, y-1}, {x, y+1}
        }
        
        for _, point in ipairs(adjacentPoints) do
            local px, py = point[1], point[2]
            if px >= 1 and px <= HeightmapSize.width and 
               py >= 1 and py <= HeightmapSize.height then
                if math.abs(Heightmap[py][px] - height) > 1 then
                    if Heightmap[py][px] < height then
                        Heightmap[py][px] = height - 1
                    else
                        Heightmap[py][px] = height + 1
                    end
                    changed = true
                    TerrainSystem.autoLevel(px, py)
                end
            end
        end
        
        return changed
    end
}
--[[ 
=============================================================
MÓDULO 7: SISTEMA DE OBJETOS
=============================================================
]]--

Objects = {
    -- Factor de escala base para los objetos
    scales = {
        tree = 64/195,    -- Escala para que el árbol ocupe un tile
        house = 64/195    -- Escala para que la casa ocupe un tile
    },

    -- Offset vertical para cada tipo de objeto
    offsets = {
        tree = {x = 0, y = -32},  -- Ajusta estos valores según necesites
        house = {x = 0, y = -32}  -- Ajusta estos valores según necesites
    },

    -- Estado de construcción actual
    buildState = {
        rotating = false,
        currentRotation = "right"
    },

    init = function()
        -- Cargar sprites con configuración optimizada
        ObjectSprites.tree = love.graphics.newImage("tree.png")
        ObjectSprites.tree:setFilter("nearest", "nearest")
        
        ObjectSprites.house_right = love.graphics.newImage("house_right.png")
        ObjectSprites.house_right:setFilter("nearest", "nearest")
        
        ObjectSprites.house_left = love.graphics.newImage("house_left.png")
        ObjectSprites.house_left:setFilter("nearest", "nearest")
        
        -- Inicializar tabla de objetos
        for y = 1, MapSize.height do
            GameObjects[y] = {}
        end
    end,

    add = function(type, x, y)
        if not GameObjects[y] then
            GameObjects[y] = {}
        end
        
        -- Determinar el sprite correcto basado en el tipo y rotación
        local spriteKey = type
        if type == "house" then
            spriteKey = "house_" .. Objects.buildState.currentRotation
        end
        
        -- Crear el nuevo objeto con offset
        GameObjects[y][x] = {
            type = type,
            sprite = ObjectSprites[spriteKey],
            scale = Objects.scales[type] or 1,
            x = x,
            y = y,
            rotation = Objects.buildState.currentRotation,
            offsetX = Objects.offsets[type].x,
            offsetY = Objects.offsets[type].y
        }
    end,

    remove = function(x, y)
        if GameObjects[y] and GameObjects[y][x] then
            GameObjects[y][x] = nil
            return true
        end
        return false
    end,

    hasObject = function(x, y)
        return GameObjects[y] and GameObjects[y][x] ~= nil
    end,

    rotate = function()
        Objects.buildState.currentRotation = 
            Objects.buildState.currentRotation == "right" and "left" or "right"
        Objects.buildState.rotating = true
    end,

    getSprite = function(type)
        if type == "house" then
            return ObjectSprites["house_" .. Objects.buildState.currentRotation]
        end
        return ObjectSprites[type]
    end,

    resetRotation = function()
        Objects.buildState.rotating = false
        Objects.buildState.currentRotation = "right"
    end,
    
    getSpriteDimensions = function(type)
        local sprite = Objects.getSprite(type)
        if sprite then
            return sprite:getWidth(), sprite:getHeight()
        end
        return 0, 0
    end,

    -- Nueva función para obtener el offset de un tipo de objeto
    getOffset = function(type)
        return Objects.offsets[type] or {x = 0, y = 0}
    end
}
--[[ 
=============================================================
MÓDULO 8: SISTEMA DE RENDERIZADO E INDICADORES VISUALES
=============================================================
]]--

Renderer = {
    currentTile = nil,

    drawTile = function(x, y)
        if not Heightmap[y] or not Heightmap[y+1] then return end
        
        local h1 = Heightmap[y][x] or 0
        local h2 = Heightmap[y][x+1] or 0
        local h3 = Heightmap[y+1][x+1] or 0
        local h4 = Heightmap[y+1][x] or 0
        
        local x1, y1 = Coordinates.isoToScreen(x-1, y-1, h1)
        local x2, y2 = Coordinates.isoToScreen(x, y-1, h2)
        local x3, y3 = Coordinates.isoToScreen(x, y, h3)
        local x4, y4 = Coordinates.isoToScreen(x-1, y, h4)
        
        if x1 and y1 and x2 and y2 and x3 and y3 and x4 and y4 then
            -- Draw base tile
            local color = TerrainSystem.getSlopeColor(h1, h2, h3, h4)
            love.graphics.setColor(color)
            love.graphics.polygon('fill', x1, y1, x2, y2, x3, y3, x4, y4)
            
            -- Draw water areas if needed
            if not TerrainSystem.isWaterTile(h1, h2, h3, h4) then
                local waterPoints = TerrainSystem.getWaterTrianglePoints(x1, y1, x2, y2, x3, y3, x4, y4, h1, h2, h3, h4)
                
                if #waterPoints >= 3 then
                    love.graphics.setColor(COLORS.water)
                    love.graphics.polygon('fill', 
                        waterPoints[1][1], waterPoints[1][2],
                        waterPoints[2][1], waterPoints[2][2],
                        waterPoints[3][1], waterPoints[3][2]
                    )
                end
            end
            
            -- Draw all tile edges with consistent style
            love.graphics.setColor(COLORS.outline)
            love.graphics.setLineWidth(LINE_WIDTH)
            love.graphics.line(x1, y1, x2, y2)
            love.graphics.line(x2, y2, x3, y3)
            love.graphics.line(x3, y3, x4, y4)
            love.graphics.line(x4, y4, x1, y1)
        end
    end,

    drawObjects = function()
        for y = 1, MapSize.height do
            for x = 1, MapSize.width do
                if GameObjects[y] and GameObjects[y][x] then
                    local obj = GameObjects[y][x]
                    local height = Heightmap[y][x]
                    
                    -- Obtener las esquinas del tile
                    local x1, y1 = Coordinates.isoToScreen(x-1, y-1, height)
                    local x2, y2 = Coordinates.isoToScreen(x, y-1, height)
                    local x3, y3 = Coordinates.isoToScreen(x, y, height)
                    local x4, y4 = Coordinates.isoToScreen(x-1, y, height)
                    
                    -- Calcular el centro del tile
                    local centerX = (x1 + x2 + x3 + x4) / 4
                    local centerY = (y3 + y4) / 2  -- Usar la base del tile
                    
                    -- Dibujar el objeto
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(
                        obj.sprite,
                        centerX,
                        centerY,
                        0,
                        obj.scale * Camera.zoom,
                        obj.scale * Camera.zoom,
                        obj.sprite:getWidth()/2,
                        obj.sprite:getHeight()
                    )
                end
            end
        end
    end,

    updateCurrentTile = function(x, y)
        if x and y and x >= 1 and x < HeightmapSize.width and 
           y >= 1 and y < HeightmapSize.height then
            Renderer.currentTile = {x = x, y = y}
        else
            Renderer.currentTile = nil
        end
    end,

    drawTerrainPoint = function()
        if not Renderer.currentTile then return end
        
        local x, y = Renderer.currentTile.x, Renderer.currentTile.y
        if x and y and Heightmap[y] then
            local screenX, screenY = Coordinates.isoToScreen(x-1, y-1, Heightmap[y][x])
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.circle("fill", screenX, screenY, 3 * Camera.zoom)
        end
    end,

    drawBuildingPreview = function()
        if not Renderer.currentTile then return end
        
        local x, y = Renderer.currentTile.x, Renderer.currentTile.y
        if x and y and Heightmap[y] and Heightmap[y][x] then
            if Heightmap[y][x] > 0 and not Objects.hasObject(x, y) then
                local height = Heightmap[y][x]
                
                -- Obtener las esquinas del tile
                local x1, y1 = Coordinates.isoToScreen(x-1, y-1, height)
                local x2, y2 = Coordinates.isoToScreen(x, y-1, height)
                local x3, y3 = Coordinates.isoToScreen(x, y, height)
                local x4, y4 = Coordinates.isoToScreen(x-1, y, height)
                
                -- Calcular el centro del tile
                local centerX = (x1 + x2 + x3 + x4) / 4
                local centerY = (y3 + y4) / 2  -- Usar la base del tile
                
                -- Obtener el sprite correcto según la rotación
                local sprite = UI.images.buildings["house_" .. UI.buildMenu.currentRotation]
                if sprite then
                    -- Dibujar preview semitransparente
                    love.graphics.setColor(1, 1, 1, 0.5)
                    love.graphics.draw(
                        sprite,
                        centerX,
                        centerY,
                        0,
                        Objects.scales.house * Camera.zoom,
                        Objects.scales.house * Camera.zoom,
                        sprite:getWidth()/2,
                        sprite:getHeight()
                    )
                end
                
                -- Dibujar borde verde para indicar que se puede construir
                love.graphics.setColor(0, 1, 0, 1)
            else
                -- Dibujar borde rojo si no se puede construir
                love.graphics.setColor(1, 0, 0, 1)
            end
            
            -- Dibujar el borde del tile
            love.graphics.setLineWidth(2)
            local x1, y1 = Coordinates.isoToScreen(x-1, y-1, height)
            local x2, y2 = Coordinates.isoToScreen(x, y-1, height)
            local x3, y3 = Coordinates.isoToScreen(x, y, height)
            local x4, y4 = Coordinates.isoToScreen(x-1, y, height)
            love.graphics.line(x1, y1, x2, y2, x3, y3, x4, y4, x1, y1)
        end
    end,

    drawTileBorder = function()
        if not Renderer.currentTile then return end
        
        local x, y = Renderer.currentTile.x, Renderer.currentTile.y
        if x and y and Heightmap[y] and Heightmap[y][x] then
            local activeTool = UI.getActiveTool()
            if activeTool and activeTool:find("house") then
                Renderer.drawBuildingPreview()
            else
                -- Borde normal para otras herramientas
                love.graphics.setColor(1, 0, 0, 1)
                love.graphics.setLineWidth(2)
                local x1, y1 = Coordinates.isoToScreen(x-1, y-1, Heightmap[y][x])
                local x2, y2 = Coordinates.isoToScreen(x, y-1, Heightmap[y][x])
                local x3, y3 = Coordinates.isoToScreen(x, y, Heightmap[y][x])
                local x4, y4 = Coordinates.isoToScreen(x-1, y, Heightmap[y][x])
                love.graphics.line(x1, y1, x2, y2, x3, y3, x4, y4, x1, y1)
            end
        end
    end,

    drawIndicators = function()
        local tool = UI.getActiveTool()
        if tool then
            if tool:find("terrain") then
                Renderer.drawTerrainPoint()
            else
                Renderer.drawTileBorder()
            end
        end
    end
}
--[[ 
=============================================================
MÓDULO 9: SISTEMA DE MODIFICACIÓN DE TERRENO 
=============================================================
]]--

local function handleToolAction(tool, x, y)
    -- Verificar coordenadas válidas
    if not (x >= 1 and x < HeightmapSize.width and 
            y >= 1 and y < HeightmapSize.height) then
        return
    end

    -- Verificar si el tile está ocupado
    local isOccupied = Objects.hasObject(x, y)

    if tool == "terrain_up" then
        -- No permitir modificación si hay un objeto
        if not isOccupied then
            Heightmap[y][x] = Heightmap[y][x] + 1
            TerrainSystem.autoLevel(x, y)
        end
    elseif tool == "terrain_down" then
        -- No permitir modificación si hay un objeto
        if not isOccupied then
            Heightmap[y][x] = math.max(0, Heightmap[y][x] - 1)
            TerrainSystem.autoLevel(x, y)
        end
    elseif tool == "tree" then
        if Heightmap[y][x] > 0 and not isOccupied then
            Objects.add("tree", x, y)
        end
    elseif tool:find("house_") then
        if Heightmap[y][x] > 0 and not isOccupied then
            -- Extraer la dirección del nombre de la herramienta
            local direction = tool:match("house_(%w+)")
            Objects.add("house", x, y)
            
            -- Limpiar estado de UI
            UI.buildMenu.selected = nil
            for _, btn in ipairs(UI.buttons) do
                if btn.id == "house" then
                    btn.selected = false
                end
            end
            UI.activeButton = nil
        end
    elseif tool == "destroy" then
        -- Permitir demoler objetos pero no bajar el terreno si hay objeto
        if isOccupied then
            Objects.remove(x, y)
        else
            Heightmap[y][x] = math.max(0, Heightmap[y][x] - 1)
            TerrainSystem.autoLevel(x, y)
        end
    end
end

TerrainSystem.autoLevel = function(x, y)
    if not Heightmap[y] or not Heightmap[y][x] then return false end
    
    local height = Heightmap[y][x]
    local changed = false
    
    local adjacentPoints = {
        {x-1, y}, {x+1, y},
        {x, y-1}, {x, y+1}
    }
    
    for _, point in ipairs(adjacentPoints) do
        local px, py = point[1], point[2]
        if px >= 1 and px <= HeightmapSize.width and 
           py >= 1 and py <= HeightmapSize.height then
            -- No nivelar si hay un objeto en el tile adyacente
            if not Objects.hasObject(px, py) then
                if math.abs(Heightmap[py][px] - height) > 1 then
                    if Heightmap[py][px] < height then
                        Heightmap[py][px] = height - 1
                    else
                        Heightmap[py][px] = height + 1
                    end
                    changed = true
                    TerrainSystem.autoLevel(px, py)
                end
            end
        end
    end
    
    return changed
end
--[[ 
=============================================================
MÓDULO 10: CALLBACKS DE LÖVE2D 
=============================================================
]]--

function love.load()
    -- Configurar gráficos para mejor calidad de píxeles
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    love.graphics.setLineStyle("rough")
    love.graphics.setBackgroundColor(0, 0, 0)
    
    -- Initialize heightmap
    for y = 1, HeightmapSize.height do
        Heightmap[y] = {}
        for x = 1, HeightmapSize.width do
            Heightmap[y][x] = 0
        end
    end
    
    -- Inicializar sistemas
    UI.load()
    Objects.init()
end

function love.update(dt)
    -- Actualizar cámara
    local cameraSpeed = Camera.moveSpeed * dt
    if love.keyboard.isDown('w') then
        Camera.y = Camera.y + cameraSpeed
    end
    if love.keyboard.isDown('s') then
        Camera.y = Camera.y - cameraSpeed
    end
    if love.keyboard.isDown('a') then
        Camera.x = Camera.x + cameraSpeed
    end
    if love.keyboard.isDown('d') then
        Camera.x = Camera.x - cameraSpeed
    end
    
    -- Actualizar UI
    UI.update()
end

function love.draw()
    love.graphics.setBackgroundColor(0, 0, 0)
    
    -- Dibujar el terreno y los objetos
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth() / 2 + Camera.x,
                          love.graphics.getHeight() / 4 + Camera.y + UI.getToolbarHeight())
    
    -- Dibujar terreno
    for y = 1, MapSize.height do
        for x = 1, MapSize.width do
            Renderer.drawTile(x, y)
        end
    end
    
    -- Dibujar objetos
    Renderer.drawObjects()
    
    -- Dibujar indicadores
    Renderer.drawIndicators()
    
    love.graphics.pop()
    
    -- Dibujar la UI encima
    UI.draw()
end

function love.mousepressed(x, y, button)
    -- Primero verificar si el click fue en la UI
    if UI.mousePressed(x, y, button) then
        return
    end
    
    -- Si no fue en la UI, procesar el click para el terreno
    if button == 1 then
        local isoX, isoY = Coordinates.screenToIso(x, y)
        
        -- Verificar que las coordenadas son válidas y que el punto está realmente dentro del tile
        if isoX >= 1 and isoX < HeightmapSize.width and 
           isoY >= 1 and isoY < HeightmapSize.height and
           Coordinates.isPointInTile(isoX, isoY, x, y) then
            
            local activeTool = UI.getActiveTool()
            if activeTool then
                handleToolAction(activeTool, isoX, isoY)
            end
        end
    elseif button == 3 then
        -- Iniciar arrastre con el botón derecho
        Camera.dragStart = {x = x - Camera.x, y = y - Camera.y}
    end
end

function love.mousereleased(x, y, button)
    if button == 3 then
        Camera.dragStart = nil
    end
end

function love.mousemoved(x, y)
    -- Manejar el arrastre de la cámara
    if Camera.dragStart then
        Camera.x = x - Camera.dragStart.x
        Camera.y = y - Camera.dragStart.y
    end
    
    -- Calcular coordenadas isométricas
    local isoX, isoY = Coordinates.screenToIso(x, y)
    
    -- Actualizar el tile actual solo si el punto está realmente dentro del tile
    if isoX >= 1 and isoX < HeightmapSize.width and 
       isoY >= 1 and isoY < HeightmapSize.height and
       Coordinates.isPointInTile(isoX, isoY, x, y) then
        Renderer.updateCurrentTile(isoX, isoY)
    else
        Renderer.updateCurrentTile(nil, nil)
    end
end

function love.wheelmoved(x, y)
    local oldZoom = Camera.zoom
    local newZoom = math.max(0.25, math.min(4, Camera.zoom + y * 0.1))
    
    if newZoom ~= oldZoom then
        Camera.zoom = newZoom
        
        -- Ajustar la posición de la cámara para mantener el punto bajo el mouse fijo
        local mouseX, mouseY = love.mouse.getPosition()
        local zoomFactor = newZoom / oldZoom
        
        -- Calcular el desplazamiento relativo al centro de la pantalla
        local dx = mouseX - love.graphics.getWidth() / 2
        local dy = mouseY - love.graphics.getHeight() / 2
        
        -- Aplicar el ajuste de zoom manteniendo el punto bajo el cursor
        Camera.x = Camera.x * zoomFactor
        Camera.y = Camera.y * zoomFactor
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'r' then
        -- Rotar edificio solo si está seleccionada la herramienta de construcción
        if UI.getActiveTool() and UI.getActiveTool():find("house") then
            UI.rotateBuilding()
        end
    end
end