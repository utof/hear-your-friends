local Umg=require('ModMenu.core.umg')
local Slider=require('slider')
local M={}
local CYAN={R=.6,G=1,B=1,A=1}
local function valid(object) return object~=nil and object:IsValid() end
local function owned(widget) return widget:GetFName():ToString():match('^HYF_')~=nil end
local function children(panel)
    local result={}
    for i=0,panel:GetChildrenCount()-1 do result[#result+1]=panel:GetChildAt(i) end
    return result
end
function M.isPlayerRow(row)
    if not valid(row) or not valid(row.PlayerState) then return false end
    local path=row:GetFullName()
    return path:find('/Engine/Transient',1,true)~=nil and path:find('W_PlayerMenu.',1,true)~=nil
        and path:find('W_PlayerList_1.',1,true)~=nil
end
local function clean(panel)
    for _,child in ipairs(children(panel)) do if owned(child) then child:RemoveFromParent() end end
end
local function moveChildren(from,to,method)
    for _,child in ipairs(children(from)) do child:RemoveFromParent();to[method](to,child) end
end
function M.new(state,handlers,tag,locale)
    local self={panels={},rows={},controls={},buttons={}}
    local serial=0
    local font=StaticFindObject('/Game/Blueprints/Widgets/Fonts/texgyreadventor_Font.texgyreadventor_Font')
    local slate=StaticFindObject('/Script/UMG.Default__SlateBlueprintLibrary')
    local language=locale.language
    local function name(suffix) serial=serial+1;return 'HYF_'..tag..'_'..suffix..'_'..serial end
    local function styleText(widget,size,color)
        if valid(font) then widget.Font.FontObject=font;widget.Font.TypefaceFontName=FName('Bold') end
        Umg.StyleText(widget,size or 14,color or CYAN)
    end
    local skin={Construct=Umg.Construct,SetLabelText=Umg.SetLabelText,StyleText=styleText}
    local function label(parent,title,size)
        local widget=Umg.Construct('/Script/UMG.TextBlock',parent,name('Caption'))
        styleText(widget,size)
        Umg.SetLabelText(widget,title)
        return widget
    end
    local function pad(top) return {Left=0,Top=top or 0,Right=10,Bottom=0} end
    local function button(parent,title,action,size,top)
        local widget=Umg.Construct('/Script/UMG.Button',parent,name('Button'))
        local caption=label(widget,title,size or 11)
        widget:SetContent(caption)
        local style=widget.WidgetStyle
        for key,color in pairs({Normal={R=.025,G=.12,B=.13,A=1},Hovered={R=.05,G=.24,B=.25,A=1},Pressed={R=.08,G=.32,B=.33,A=1}}) do
            style[key].DrawAs=3;style[key].ResourceObject=nil
            style[key].TintColor={SpecifiedColor=color,ColorUseRule=0}
        end
        style.NormalPadding={Left=10,Top=5,Right=10,Bottom=5}
        style.PressedPadding=style.NormalPadding
        local slot=parent:AddChildToHorizontalBox(widget)
        slot:SetPadding(pad(top));slot:SetVerticalAlignment(2)
        local control={widget=widget,action=action,pressed=false}
        self.buttons[#self.buttons+1]=control
        return caption,control
    end
    local function addSlider(parent,key,title)
        local value=key and (state.levels[key] or 1) or state.master
        local line=Umg.Construct('/Script/UMG.HorizontalBox',parent,name('Control'))
        local root,control=Slider.create(skin,line,name('Voice'),title,value,function(level)
            if key then handlers.player(key,level) else handlers.master(level) end
        end,14,true)
        local slot=line:AddChildToHorizontalBox(root)
        slot:SetSize({SizeRule=1,Value=1});slot:SetVerticalAlignment(2)
        local _,reset=button(line,locale:t('reset'),function() Slider.reset(control) end,11)
        control.key,control.reset=key,reset.widget
        reset.owner=control
        self.controls[#self.controls+1]=control
        return line,control
    end
    local function placeFooter(panel)
        local canvas=panel.menu.PlayerMenu
        local geometry=panel.menu.W_PlayerList_1:GetCachedGeometry()
        local size=slate:GetLocalSize(geometry)
        if size.X<=0 or size.Y<=0 then return end
        local parent=canvas:GetCachedGeometry()
        local left=slate:AbsoluteToLocal(parent,slate:LocalToAbsolute(geometry,{X=0,Y=size.Y}))
        local right=slate:AbsoluteToLocal(parent,slate:LocalToAbsolute(geometry,{X=size.X,Y=size.Y}))
        panel.width:SetWidthOverride(right.X-left.X)
        panel.slot:SetAnchors({Minimum={X=0,Y=0},Maximum={X=0,Y=0}})
        panel.slot:SetOffsets({Left=left.X,Top=left.Y+12,Right=right.X-left.X,Bottom=180})
    end
    function self:mountPanel(menu)
        local canvas=menu.PlayerMenu
        clean(canvas)
        local firstButton=#self.buttons+1
        local width=Umg.Construct('/Script/UMG.SizeBox',canvas,name('PanelWidth'))
        width:SetWidthOverride(790)
        local box=Umg.Construct('/Script/UMG.VerticalBox',width,name('Panel'))
        width:SetContent(box)
        local master=addSlider(box,nil,locale:t('native_master'))
        box:AddChildToVerticalBox(master)
        local hint=label(box,locale:t('range_hint'),11)
        Umg.EnableAutoWrap(hint)
        local hintSlot=box:AddChildToVerticalBox(hint)
        hintSlot:SetPadding({Left=0,Top=6,Right=0,Bottom=10})
        local mic=Umg.Construct('/Script/UMG.HorizontalBox',box,name('Mic'))
        box:AddChildToVerticalBox(mic)
        local micLabel=label(mic,locale:t('mic_label'),12)
        local micSlot=mic:AddChildToHorizontalBox(micLabel)
        micSlot:SetPadding(pad());micSlot:SetVerticalAlignment(2)
        local micCaption=button(mic,'',function() handlers.solo(not state.solo) end,11)
        local micHint=label(box,'',10)
        Umg.EnableAutoWrap(micHint)
        box:AddChildToVerticalBox(micHint)
        local actions=Umg.Construct('/Script/UMG.HorizontalBox',box,name('Utilities'))
        box:AddChildToVerticalBox(actions)
        button(actions,locale:t('native_report'),handlers.report,11,12)
        button(actions,locale:t('native_support'),handlers.donate,11,12)
        local slot=canvas:AddChildToCanvas(width)
        -- Initial position until the native list has a completed layout prepass.
        slot:SetAnchors({Minimum={X=.025,Y=.715},Maximum={X=.44,Y=.715}})
        slot:SetOffsets({Left=0,Top=0,Right=0,Bottom=180})
        slot:SetAutoSize(true);slot:SetZOrder(5)
        local panel={menu=menu,slot=slot,width=width,micCaption=micCaption,micHint=micHint}
        self.panels[menu:GetAddress()]=panel
        for i=firstButton,#self.buttons do self.buttons[i].menu=menu end
        placeFooter(panel)
    end
    function self:mountRow(row,key)
        local size=row.WidgetTree.RootWidget
        local overlay=size:GetChildAt(0)
        local header
        for _,child in ipairs(children(overlay)) do
            if child:GetFName():ToString()=='HorizontalBox_1' then header=child end
        end
        assert(valid(header),'Native player identity line unavailable')
        local actions
        for _,child in ipairs(children(header)) do
            if child:GetFName():ToString()=='HorizontalBox_0' then actions=child end
        end
        assert(valid(actions),'Native player actions unavailable')
        -- Recover native buttons from our previous wrapper before Lua hot reload.
        for _,child in ipairs(children(overlay)) do
            if owned(child) and child:GetFName():ToString():find('_Actions_',1,true) then
                moveChildren(child,actions,'AddChildToHorizontalBox')
            end
        end
        clean(overlay)
        local width=slate:GetLocalSize(row:GetCachedGeometry()).X
        if width<=0 then width=790 end
        local wrap=Umg.Construct('/Script/UMG.WrapBox',overlay,name('Actions'))
        -- Automatic wrapping feeds the previous frame's desired width back into
        -- row height. Constrain it before Slate creates the panel (5.4 has no
        -- reflected SetWrapSize/SetExplicitWrapSize setters).
        wrap.bExplicitWrapSize=true
        wrap.WrapSize=math.max(1,width-24)
        wrap:SetInnerSlotPadding({X=0,Y=4})
        wrap:SetVisibility(1)
        local wrapSlot=overlay:AddChildToOverlay(wrap)
        wrapSlot:SetVerticalAlignment(1)
        wrapSlot:SetHorizontalAlignment(0)
        wrapSlot:SetPadding({Left=12,Top=36,Right=12,Bottom=0})
        local border=Umg.Construct('/Script/UMG.Border',overlay,name('Row'))
        border:SetBrushColor({R=.008,G=.025,B=.025,A=1})
        border:SetPadding({Left=12,Top=3,Right=12,Bottom=3})
        local player=state.players[key]
        local line,control=addSlider(border,key,locale:t(player.local_player and 'native_local' or 'native_voice'))
        border:SetContent(line)
        local slot=overlay:AddChildToOverlay(border)
        slot:SetVerticalAlignment(3);slot:SetHorizontalAlignment(0)
        slot:SetPadding({Left=0,Top=0,Right=0,Bottom=4})
        if player.name then row.Name:SetToolTipText(FText(player.name)) end
        local old=self.rows[row:GetAddress()]
        if old then old.control.retired=true end
        local entry={row=row,key=key,control=control,size=size,overlay=overlay,header=header,actions=actions,wrap=wrap,width=width,wrapped=false}
        self.rows[row:GetAddress()]=entry
        self:layoutRow(entry)
    end
    function self:layoutRow(entry)
        local width=slate:GetLocalSize(entry.row:GetCachedGeometry()).X
        if width<=0 then width=entry.width end
        if math.abs(width-entry.width)>1 then
            -- Rebuild only on a measured resize so the new Slate panel receives
            -- its explicit width; retain the last width while geometry is absent.
            self:mountRow(entry.row,entry.key)
            return
        end
        local actionWidth=0
        local source=entry.wrapped and entry.wrap or entry.actions
        for _,child in ipairs(children(source)) do
            local visibility=child:GetVisibility()
            if visibility~=1 and visibility~=2 then actionWidth=actionWidth+child:GetDesiredSize().X end
        end
        local parentVisibility=entry.actions:GetVisibility()
        local headerVisibility=entry.header:GetVisibility()
        local available=parentVisibility~=1 and parentVisibility~=2 and headerVisibility~=1 and headerVisibility~=2
        local crowded=available and actionWidth>width-320
        if crowded~=entry.wrapped then
            if crowded then moveChildren(entry.actions,entry.wrap,'AddChildToWrapBox')
            else moveChildren(entry.wrap,entry.actions,'AddChildToHorizontalBox') end
            entry.wrapped=crowded
        end
        local visibility=(parentVisibility==3 or headerVisibility==3) and 3 or 4
        entry.wrap:SetVisibility(crowded and visibility or 1)
        entry.wrap:SetIsEnabled(entry.actions:GetIsEnabled() and entry.header:GetIsEnabled())
        local actionHeight=crowded and math.max(30,entry.wrap:GetDesiredSize().Y) or 0
        local height=72+(crowded and actionHeight+4 or 0)
        entry.size:SetHeightOverride(height)
        entry.header.Slot:SetVerticalAlignment(1)
        entry.header.Slot:SetPadding({Left=0,Top=4,Right=0,Bottom=0})
        for _,child in ipairs(children(entry.overlay)) do
            if not owned(child) and child:GetAddress()~=entry.header:GetAddress() then
                child.Slot:SetPadding({Left=0,Top=0,Right=0,Bottom=height-36})
            end
        end
    end
    function self:refreshRows()
        for _,entry in pairs(self.rows) do if valid(entry.row) then self:layoutRow(entry) end end
        for i=#self.controls,1,-1 do
            local control=self.controls[i]
            if control.retired or not valid(control.slider) then table.remove(self.controls,i)
            else
                local value=control.key and (state.levels[control.key] or 1) or state.master
                if math.abs(value-control.last)>.0001 then Slider.apply(control,value) end
                local player=control.key and state.players[control.key]
                local enabled=not control.key or (player~=nil and (not player.local_player or state.solo))
                control.slider:SetIsEnabled(enabled);control.reset:SetIsEnabled(enabled)
                local hint=control.key and locale:t('effective',state:effective(control.key),state.master,value) or locale:t('range_hint')
                if player and player.local_player and not state.solo then hint=locale:t('mic_hint') end
                control.slider:SetToolTipText(FText(hint))
            end
        end
    end
    function self:refresh(monitorReady)
        if language~=locale.language then
            language=locale.language
            for _,control in ipairs(self.controls) do control.retired=true end
            self.panels,self.rows,self.buttons={},{},{}
        end
        for address,panel in pairs(self.panels) do if not valid(panel.menu) then self.panels[address]=nil end end
        for address,entry in pairs(self.rows) do
            if not M.isPlayerRow(entry.row) then entry.control.retired=true;self.rows[address]=nil end
        end
        for _,menu in pairs(FindAllOf('W_PlayerMenu_C') or {}) do
            if valid(menu) and valid(menu.PlayerMenu) and menu:GetFullName():find('/Engine/Transient',1,true) and not self.panels[menu:GetAddress()] then self:mountPanel(menu) end
        end
        for _,row in pairs(FindAllOf('W_HUD_PlayerListRow_C') or {}) do
            if M.isPlayerRow(row) then
                local key=row.PlayerState:GetFName():ToString()
                local old=self.rows[row:GetAddress()]
                if state.players[key] and (not old or old.key~=key) then self:mountRow(row,key) end
            end
        end
        self:refreshRows()
        for _,panel in pairs(self.panels) do
            placeFooter(panel)
            Umg.SetLabelText(panel.micCaption,locale:t(state.solo and 'mic_stop' or 'mic_apply'))
            Umg.SetLabelText(panel.micHint,locale:t(state.solo and not monitorReady and 'monitor_pending' or 'mic_hint'))
        end
        for i=#self.buttons,1,-1 do
            local button=self.buttons[i]
            if not valid(button.widget) or (button.owner and button.owner.retired) or (button.menu and not valid(button.menu)) then table.remove(self.buttons,i) end
        end
    end
    function self:poll()
        for _,control in ipairs(self.controls) do
            if valid(control.slider) and (not control.key or state.players[control.key]) then Slider.poll(control) end
        end
        for _,control in ipairs(self.buttons) do
            if valid(control.widget) and not (control.owner and control.owner.retired) then
                local pressed=control.widget:IsPressed()
                if pressed and not control.pressed then control.action() end
                control.pressed=pressed
            end
        end
    end
    return self
end
return M
