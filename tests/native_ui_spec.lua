package.preload['ModMenu.core.umg']=function() return {} end
package.preload['slider']=function() return {} end
local ui=assert(loadfile('Mods/HearYourFriends/Scripts/native_ui.lua'),'native UI missing')()
local function row(path,valid)
 return {GetFullName=function() return path end,IsValid=function() return true end,
 PlayerState={IsValid=function() return valid end}}
end
assert(ui.isPlayerRow(row('/Engine/Transient.W_PlayerMenu.WidgetTree.W_PlayerList_1.Row',true)), 'targets current Players list')
assert(not ui.isPlayerRow(row('/Game/Templates.W_PlayerMenu.W_PlayerList_1.Row',true)), 'does not edit class templates')
assert(not ui.isPlayerRow(row('/Engine/Transient.W_PlayerMenu.W_PlayerList_MutedPlayers.Row',true)), 'does not alter muted or blocked lists')
assert(not ui.isPlayerRow(row('/Engine/Transient.W_ServerAdminMenu.W_PlayerList.Row',true)), 'does not alter administration rows')
assert(not ui.isPlayerRow(row('/Engine/Transient.W_PlayerMenu.W_PlayerList_1.Row',false)), 'ignores rows with no bound player')
print('native UI scope tests passed')
-- Exercise mounting against UMG's sizing and parent/child contracts.
local Umg=require('ModMenu.core.umg')
local function slot()
    return setmetatable({}, {__index=function(_,key)
        assert(key:match('^Set'),key)
        return function(self,value) self[key:sub(4)]=value end
    end})
end
local id=0
local function widget(kind,name)
    id=id+1
    local w={kind=kind,name=name or kind,children={},address=id,visibility=0,enabled=true,
        desired={X=0,Y=0},geometry={size={X=790,Y=72},origin={X=0,Y=0}},WidgetStyle={Normal={},Hovered={},Pressed={}}}
    function w:IsValid() return true end
    function w:GetFName() return {ToString=function() return self.name end} end
    function w:GetAddress() return self.address end
    function w:GetChildrenCount() return #self.children end
    function w:GetChildAt(i) return self.children[i+1] end
    function w:GetChild() return self.children[1] end
    function w:RemoveFromParent()
        if not self.parent then return end
        for i,child in ipairs(self.parent.children) do if child==self then table.remove(self.parent.children,i);break end end
        self.parent=nil
    end
    function w:AddChild(child)
        assert(not child.parent,'remove before reparenting')
        self.children[#self.children+1]=child;child.parent=self;child.Slot=slot();return child.Slot
    end
    w.AddChildToHorizontalBox,w.AddChildToVerticalBox,w.AddChildToOverlay,w.AddChildToCanvas,w.AddChildToWrapBox=w.AddChild,w.AddChild,w.AddChild,w.AddChild,w.AddChild
    function w:SetContent(child) self:AddChild(child) end
    function w:GetCachedGeometry() return self.geometry end
    function w:GetDesiredSize()
        if self.width then return {X=self.width,Y=100} end
        if #self.children>0 then
            local width=0
            for _,child in ipairs(self.children) do width=math.max(width,child:GetDesiredSize().X) end
            return {X=width,Y=100}
        end
        return self.desired
    end
    function w:SetWidthOverride(width) self.width=width end
    function w:SetHeightOverride(height) self.height=height end
    function w:SetVisibility(value) self.visibility=value end
    function w:GetVisibility() return self.visibility end
    function w:SetIsEnabled(value) self.enabled=value end
    function w:GetIsEnabled() return self.enabled end
    function w:SetBrushColor() end
    function w:SetPadding() end
    function w:SetInnerSlotPadding() end
    function w:SetToolTipText() end
    return w
end
Umg.Construct=function(kind,_,name) return widget(kind,name) end
Umg.StyleText=function() end
Umg.SetLabelText=function(w,text) w.text=text;w.desired.X=#text*7 end
Umg.EnableAutoWrap=function() end
local slider=require('slider')
slider.create=function(_,_,name,caption,value)
    local w=widget('slider',name)
    return w,{slider=w,last=value}
end
slider.apply=function(control,value) control.last=value end
slider.reset=function() end
local slate={}
function slate:GetLocalSize(geometry) return geometry.size end
function slate:LocalToAbsolute(geometry,point) return {X=geometry.origin.X+point.X,Y=geometry.origin.Y+point.Y} end
function slate:AbsoluteToLocal(geometry,point) return {X=point.X-geometry.origin.X,Y=point.Y-geometry.origin.Y} end
StaticFindObject=function(path) if path:find('SlateBlueprintLibrary',1,true) then return slate end end
FText=function(text) return text end
local state={master=1,solo=false,players={remote={name='Remote',local_player=false}},levels={}}
function state:effective(key) return self.master*(self.levels[key] or 1) end
local locale={language='en',t=function(_,key) return key=='range_hint' and string.rep('Long translated hint ',100) or key end}
local function nativeRow()
    local row=widget('PlayerRow')
    row.WidgetTree={RootWidget=widget('SizeBox')}
    local overlay=widget('Overlay');row.WidgetTree.RootWidget:SetContent(overlay)
    overlay:AddChild(widget('Image','Background'))
    local header=widget('HorizontalBox','HorizontalBox_1');overlay:AddChild(header)
    local actions=widget('HorizontalBox','HorizontalBox_0');header:AddChild(actions)
    row.Name=widget('TextBlock','Name')
    local buttons={}
    for i=1,4 do local button=widget('Button','Native'..i);button.desired.X=150;actions:AddChild(button);buttons[i]=button end
    return row,header,actions,buttons
end
local menu=widget('PlayerMenu');menu.PlayerMenu=widget('CanvasPanel');menu.W_PlayerList_1=widget('Roster')
menu.PlayerMenu.geometry.origin={X=20,Y=30}
menu.W_PlayerList_1.geometry={origin={X=60,Y=100},size={X=800,Y=500}}
local mounted=ui.new(state,{},'test',locale)
mounted:mountPanel(menu)
local footer=menu.PlayerMenu.children[1]
assert(footer.Slot.AutoSize,'footer height follows translated content')
assert(footer:GetDesiredSize().X==800,'auto-sized footer remains constrained to the measured roster width')
assert(footer.Slot.Offsets.Left==40 and footer.Slot.Offsets.Top==582,'footer uses canvas-local roster coordinates')
local testRow,header,actions,buttons=nativeRow()
mounted:mountRow(testRow,'remote')
local entry=mounted.rows[testRow:GetAddress()]
assert(entry.wrapped and #actions.children==0 and #entry.wrap.children==4,'crowded actions move together below identity')
for i,button in ipairs(buttons) do assert(entry.wrap.children[i]==button,'reparenting retains native objects and order') end
header:SetIsEnabled(false);header:SetVisibility(3);mounted:layoutRow(entry)
assert(entry.wrap:GetVisibility()==3 and not entry.wrap:GetIsEnabled(),'wrapper preserves inherited disabled and hit-test rules')
actions:SetVisibility(1);mounted:layoutRow(entry)
assert(not entry.wrapped and entry.wrap:GetVisibility()==1,'hidden native action container cannot reveal actions')
actions:SetVisibility(0);header:SetVisibility(0);header:SetIsEnabled(true)
mounted:layoutRow(entry)
assert(entry.wrapped,'actions wrap again after the native group is shown')
-- A new Lua UI instance must recover the actual native buttons before cleaning its old wrappers.
local reloaded=ui.new(state,{},'next',locale)
reloaded:mountRow(testRow,'remote')
local nextEntry=reloaded.rows[testRow:GetAddress()]
assert(#nextEntry.wrap.children==4,'hot reload keeps all native actions without duplicates')
for i,button in ipairs(buttons) do assert(nextEntry.wrap.children[i]==button,'hot reload preserves action identity and order') end
print('native UI layout contracts passed')
