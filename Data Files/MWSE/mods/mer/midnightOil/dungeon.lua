local common = require("mer.midnightOil.common")
local logger = common.createLogger("dungeon")
local config = require("mer.midnightOil.config").getConfig()

local Dungeon = {}

---@param cell tes3cell
function Dungeon.cellIsDungeon(cell)
    --A dungeon is an interior cell
    if not cell.isInterior then
        logger:debug("Cell %s is not an interior cell", cell.id)
        return false
    end
    --A dungeon has no NPCs
    for ref in cell:iterateReferences(tes3.objectType.npc) do
        if not (ref.isDead or ref.disabled) then
            logger:debug("Cell %s has NPCs", cell.id)
            return false
        end
    end
    return true
end

---@param cell tes3cell
function Dungeon:new(cell)
    logger:debug("Attempting to create dungeon for cell %s", cell.id)
    if not Dungeon.cellIsDungeon(cell) then
        logger:debug("Cell %s is not a dungeon", cell.id)
        return nil
    end
    logger:debug("Cell %s is a dungeon", cell.id)
    local dungeon = {
        cell = cell,
    }
    setmetatable(dungeon, self)
    self.__index = self
    return dungeon
end

function Dungeon:isProcessed()
    local isProcessed = tes3.player.data.tmo_processedDungeons
        and tes3.player.data.tmo_processedDungeons[self.cell.id]
    logger:debug("Dungeon %s has been processed: %s", self.cell.id, isProcessed)
    return isProcessed
end

function Dungeon:setProcessed()
    logger:debug("Setting dungeon %s as processed", self.cell.id)
    if not tes3.player.data.tmo_processedDungeons then
        logger:debug("Creating tmo_processedDungeons table")
        tes3.player.data.tmo_processedDungeons = {}
    end
    tes3.player.data.tmo_processedDungeons[self.cell.id] = true
end

function Dungeon:processLights()
    logger:debug("Processing dungeon %s", self.cell.id)
    if self:isProcessed() then
        logger:debug("Dungeon %s has already been processed", self.cell.id)
        return
    end
    for reference in self.cell:iterateReferences(tes3.objectType.light) do
        logger:trace("Processing light %s", reference.object.id)
        if not reference.supportsLuaData then
            logger:trace("Reference %s does not support lua data", reference.object.id)
            --Can't support lua data
            return
        end
        if not reference.sceneNode then
            logger:trace("Reference %s has no scene node", reference.object.id)
            --No scene node
            return
        end
        if (config.staticLightsOnly and reference.object.canCarry) then
            logger:trace("Reference %s is a carryable light", reference.object.id)
            --Carryable light when staticLightsOnly is set
            return
        end
        if not common.isSwitchable(reference.object) then
            logger:trace("Reference %s is not a switchable light", reference.object.id)
            --Not a switchable light
            return
        end
        logger:debug("Removing light %s", reference.object.id)
        common.removeLight(reference)
    end
    logger:debug("Dungeon %s has been processed", self.cell.id)
    self:setProcessed()
end



return Dungeon