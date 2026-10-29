local M = {}
local function slider(value)
    if type(value) ~= 'number' or value ~= value or math.abs(value) == math.huge then return nil end
    return math.max(0,math.min(4,value))
end
function M.new(config)
    local self = {master=slider(config.gain) or 1,solo=config.soloTest==true,players={},levels={}}
    function self:setMaster(value)
        self.master = slider(value) or self.master
    end
    function self:setPlayer(key,value)
        if self.players[key] and slider(value) then self.levels[key]=slider(value) end
    end
    function self:sync(players)
        self.players={}
        for _,player in ipairs(players) do self.players[player.key]=player end
        for key in pairs(self.levels) do if not self.players[key] then self.levels[key]=nil end end
    end
    function self:effective(key)
        return self.master*(self.levels[key] or 1)
    end
    return self
end
return M
