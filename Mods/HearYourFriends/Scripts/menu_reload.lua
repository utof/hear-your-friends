-- ModMenu leaves its UMG tree in the world when UE4SS replaces the Lua state.
-- Reuse its shared input accounting and restoration; retain only a string tag.
local Shared = require('ModMenu.core.shared')
local InputMode = require('ModMenu.core.inputmode')
local M = {}
local TAG_KEY = 'HearYourFriends.PreviousMenuTag'

function M.prepare(currentTag)
    local previous = Shared.Get(TAG_KEY)
    Shared.Set(TAG_KEY, currentTag)
    if type(previous) ~= 'string' or previous == currentTag then return end
    local prefix = 'ModMenu_Root_' .. previous .. '_'
    for _, widget in pairs(FindAllOf('UserWidget') or {}) do
        if widget:IsValid() and widget:GetFName():ToString():sub(1, #prefix) == prefix then
            local heldInput = widget:IsInViewport() and widget:GetVisibility() == 0
            widget:RemoveFromParent()
            if heldInput then InputMode.SetActive(false, Shared.AdjustOpenCount(-1)) end
        end
    end
end

return M
