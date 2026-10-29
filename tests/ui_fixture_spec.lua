-- Preview widgets must never expose a usable native player action.
local callbacks,rows={},{}
local function widget(name)
 local w={name=name,children={},enabled=true}
 function w:IsValid() return true end
 function w:GetFName() return {ToString=function() return self.name end} end
 function w:GetChildrenCount() return #self.children end
 function w:GetChildAt(i) return self.children[i+1] end
 function w:AddChild(child)
  self.children[#self.children+1]=child;child.parent=self
  child.Slot={SetSize=function() end}
  return setmetatable({}, {__index=function() return function() end end})
 end
 w.AddChildToOverlay,w.AddChildToCanvas=w.AddChild,w.AddChild
 function w:SetVisibility(v) self.visibility=v end
 function w:SetIsEnabled(v) self.enabled=v end
 function w:SetText(v) self.text=v end
 function w:GetParent() return self.parent end
 return w
end
local function row()
 local w=widget('NativeRow');local overlay=widget('Overlay')
 w.WidgetTree={RootWidget={GetChildAt=function() return overlay end}}
 overlay:AddChild(widget('HorizontalBox_1'))
 local scale=widget('NameScale');overlay:AddChild(scale)
 w.Name=widget('Name');scale:AddChild(w.Name)
 w.StatusText,w.UniquePlayerID=widget('StatusText'),widget('UniquePlayerID')
 for _,suffix in ipairs({'HardcoreRevive','Profile','Mute','Report','Block','Kick','Ban'}) do
  w['Button_'..suffix]=widget(suffix)
 end
 return w
end
local example=row()
local menu=widget('Menu');menu.PlayerMenu=widget('Canvas')
function menu:GetFullName() return '/Engine/Transient.W_PlayerMenu' end
FindAllOf=function(class)
 if class=='W_HUD_PlayerListRow_C' then return {example} end
 assert(class=='W_PlayerMenu_C','fixture must only discover UI classes')
 return {menu}
end
local library={Create=function() local w=row();rows[#rows+1]=w;return w end}
StaticFindObject=function(path)
 assert(path=='/Script/UMG.Default__WidgetBlueprintLibrary','only the existing UI factory is used')
 return library
end
function example:GetClass() return {} end
LoopInGameThreadWithDelay=function(delay,fn) assert(delay==50);callbacks[#callbacks+1]=fn end
FText=function(text) return text end
package.preload['UEHelpers.UEHelpers']=function() return {GetWorld=function() return {} end,GetPlayerController=function() return {} end} end
package.preload['ModMenu.core.util']=function() return {PinFn=function(fn) return fn end} end
package.preload['ModMenu.core.umg']=function() return {Construct=function(_,_,name) return widget(name) end} end
package.preload['native_ui']=function() return {
 isPlayerRow=function(w) return w==example end,
 new=function() return {mountRow=function() end,refreshRows=function() end,poll=function() end} end,
} end
package.preload['state']=function() return assert(loadfile('Mods/HearYourFriends/Scripts/state.lua'))() end
local fixture=assert(loadfile('tools/ui_fixture.lua'))()
fixture.start({master=1,players={}}, {}, 'test')
callbacks[1]()
assert(#rows==5,'creates five preview widgets without player actors')
for _,w in ipairs(rows) do
 for _,suffix in ipairs({'Profile','Mute','Report','Block','Kick','Ban'}) do
  assert(not w['Button_'..suffix].enabled,'native actions cannot receive keyboard/controller activation')
  w['Button_'..suffix].enabled=true -- Simulate a native widget refresh.
 end
end
for _=1,5 do callbacks[1]() end
for _,w in ipairs(rows) do
 assert(w.Name.text and w.Name.text:find('PREVIEW',1,true),'preview identity survives native refresh')
 for _,suffix in ipairs({'Profile','Mute','Report','Block','Kick','Ban'}) do
  assert(not w['Button_'..suffix].enabled,'native refresh cannot leave preview actions enabled')
 end
end
print('UI preview input isolation passed')
