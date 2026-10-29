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
  local slot=setmetatable({}, {__index=function(_,method) return function(self,value) self[method:sub(4)]=value end end})
  child.canvasSlot=slot
  return slot
 end
 w.AddChildToOverlay,w.AddChildToCanvas=w.AddChild,w.AddChild
 function w:SetVisibility(v) self.visibility=v end
 function w:SetIsEnabled(v) self.enabled=v end
 function w:SetText(v) self.text=v end
 function w:GetParent() return self.parent end
 function w:GetCachedGeometry() return self.geometry end
 return w
end
local function row()
 local w=widget('NativeRow');local overlay=widget('Overlay')
 function w:GetFullName() return '/Engine/Transient.W_PlayerMenu.WidgetTree.W_PlayerList_1.NativeRow' end
 w.TickFrequency=1;w.pendingNativeUpdate=true
 function w:StopAnimationsAndLatentActions() self.pendingNativeUpdate=false end
 w.WidgetTree={RootWidget={GetChildAt=function() return overlay end}}
 overlay:AddChild(widget('HorizontalBox_1'))
 local scale=widget('NameScale');overlay:AddChild(scale)
 w.Name=widget('Name');scale:AddChild(w.Name)
 w.StatusText,w.UniquePlayerID=widget('StatusText'),widget('UniquePlayerID')
 for _,suffix in ipairs({'HardcoreRevive','Profile','Mute','Report','Block','Kick','Ban'}) do
  w['Button_'..suffix]=widget(suffix)
 end
 function w:nativeUpdate()
  if self.TickFrequency~=0 or self.pendingNativeUpdate then
   self.Name.text='';self.Button_Profile.visibility=1
  end
 end
 return w
end
local example=row()
local nativeList=widget('NativeList');nativeList:AddChild(example)
example.geometry={origin={X=40,Y=290},size={X=790,Y=130}}
local menu=widget('Menu');menu.PlayerMenu=widget('Canvas')
menu.PlayerMenu.geometry={origin={X=0,Y=0},size={X=1920,Y=1080}}
menu.W_PlayerList_1=widget('Roster')
menu.W_PlayerList_1.geometry={origin={X=40,Y=245},size={X=800,Y=515}}
function menu:GetFullName() return '/Engine/Transient.W_PlayerMenu' end
FindAllOf=function(class)
 if class=='W_HUD_PlayerListRow_C' then return {example} end
 assert(class=='W_PlayerMenu_C','fixture must only discover UI classes')
 return {menu}
end
local library={Create=function() local w=row();rows[#rows+1]=w;return w end}
StaticFindObject=function(path)
 if path=='/Script/UMG.Default__SlateBlueprintLibrary' then return {
  GetLocalSize=function(_,geometry)return geometry.size end,
  LocalToAbsolute=function(_,geometry,point)return {X=geometry.origin.X+point.X,Y=geometry.origin.Y+point.Y} end,
  AbsoluteToLocal=function(_,geometry,point)return {X=point.X-geometry.origin.X,Y=point.Y-geometry.origin.Y} end,
 } end
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
local preview=menu.PlayerMenu.children[1]
assert(preview.canvasSlot.Offsets.Top==426,'preview begins below the actual local row instead of overlapping it')
local old=example
old.GetCachedGeometry=function()error('native row replaced')end
example=row();nativeList:AddChild(example)
example.geometry={origin={X=40,Y=290},size={X=790,Y=60}}
for _=1,5 do callbacks[1]() end
assert(preview.canvasSlot.Offsets.Top==356,'roster rebuilds reacquire the attached native row before docking')
for _,w in ipairs(rows) do
 w:nativeUpdate() -- Native callbacks can run between any two preview polls.
 assert(w.Name.text and w.Name.text:find('PREVIEW',1,true),'preview identity survives native refresh')
 assert(w.Button_Profile.visibility==0,'preview profile stays visible between polls')
 for _,suffix in ipairs({'Profile','Mute','Report','Block','Kick','Ban'}) do
  assert(not w['Button_'..suffix].enabled,'native refresh cannot leave preview actions enabled')
 end
end
print('UI preview input isolation passed')
