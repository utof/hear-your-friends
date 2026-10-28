local shared, restored, remaining = {}, 0, nil
package.preload['ModMenu.core.shared'] = function()
    return { Get = function(key) return shared[key] end,
        Set = function(key, value) shared[key] = value end,
        AdjustOpenCount = function(delta) shared.count = shared.count + delta; return shared.count end }
end
package.preload['ModMenu.core.inputmode'] = function()
    return { SetActive = function(active, count) assert(not active); restored = restored + 1; remaining = count end }
end
local widgets = {}
FindAllOf = function(class) assert(class == 'UserWidget'); return widgets end
local function widget(name, visible)
    local w = { removed = false }
    function w:IsValid() return true end
    function w:GetFName() return {ToString = function() return name end} end
    function w:IsInViewport() return true end
    function w:GetVisibility() return visible and 0 or 1 end
    function w:RemoveFromParent() self.removed = true end
    return w
end
local loader = assert(loadfile('Mods/HearYourFriends/Scripts/menu_reload.lua'), 'reload cleanup is missing')
local prepare = loader().prepare
prepare('i1')
local old, another = widget('ModMenu_Root_i1_1', true), widget('ModMenu_Root_i99_1', true)
widgets, shared.count = {old,another}, 2
prepare('i2')
assert(old.removed and not another.removed, 'removes only this mod previous menu')
assert(restored == 1 and remaining == 1, 'uses existing input restore while another menu stays open')
prepare('i2')
assert(restored == 1, 'does not decrement input ownership twice')
widgets = {widget('ModMenu_Root_i2_1', false)}
prepare('i3')
assert(widgets[1].removed and restored == 1, 'closed widgets do not hold input')
print('menu reload tests passed')
