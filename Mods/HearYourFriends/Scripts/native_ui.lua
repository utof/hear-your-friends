local Umg=require('ModMenu.core.umg')
local Slider=require('slider')
local M={}
local CYAN={R=.6,G=1,B=1,A=1}
local function valid(object) return object~=nil and object:IsValid() end
function M.isPlayerRow(row)
    if not valid(row) or not valid(row.PlayerState) then return false end
    local path=row:GetFullName()
    return path:find('/Engine/Transient',1,true)~=nil and path:find('W_PlayerMenu.',1,true)~=nil
        and path:find('W_PlayerList_1.',1,true)~=nil
end
local function clean(panel)
    for i=panel:GetChildrenCount()-1,0,-1 do
        local child=panel:GetChildAt(i)
        if child:GetFName():ToString():match('^HYF_') then child:RemoveFromParent() end
    end
end
function M.new(state,handlers,tag,locale)
    local self={panels={},rows={},controls={},buttons={}}
    local serial=0
    local font=StaticFindObject('/Game/Blueprints/Widgets/Fonts/texgyreadventor_Font.texgyreadventor_Font')
    local language=locale.language
    local function name(suffix) serial=serial+1;return 'HYF_'..tag..'_'..suffix..'_'..serial end
    local function styleText(widget,size,color)
        if valid(font) then
            widget.Font.FontObject=font
            widget.Font.TypefaceFontName=FName('Bold')
        end
        Umg.StyleText(widget,size or 14,color or CYAN)
    end
    local skin={Construct=Umg.Construct,SetLabelText=Umg.SetLabelText,StyleText=styleText}
    local function label(parent,title,size)
        local w=Umg.Construct('/Script/UMG.TextBlock',parent,name('Caption'))
        styleText(w,size)
        Umg.SetLabelText(w,title)
        return w
    end
    local function addSlider(parent,key,title,size)
        local current=key and (state.levels[key] or 1) or state.master
        local host=Umg.Construct('/Script/UMG.SizeBox',parent,name('Width'))
        host:SetWidthOverride(440)
        local root,control=Slider.create(skin,host,name('Voice'),title,current,function(value)
            if key then handlers.player(key,value) else handlers.master(value) end
        end,size or 14)
        host:SetContent(root)
        control.key=key
        self.controls[#self.controls+1]=control
        return host,control
    end
    local function button(parent,title,action)
        local root=Umg.Construct('/Script/UMG.Button',parent,name('Button'))
        local caption=label(root,title,12)
        root:SetContent(caption)
        -- Plain teal surfaces, with the game's font and cyan hover treatment.
        local style=root.WidgetStyle
        for key,color in pairs({Normal={R=.025,G=.12,B=.13,A=1},Hovered={R=.05,G=.24,B=.25,A=1},Pressed={R=.08,G=.32,B=.33,A=1}}) do
            style[key].DrawAs=3
            style[key].ResourceObject=nil
            style[key].TintColor={SpecifiedColor=color,ColorUseRule=0}
        end
        style.NormalPadding={Left=12,Top=7,Right=12,Bottom=7}
        style.PressedPadding={Left=12,Top=7,Right=12,Bottom=7}
        local slot=parent:AddChildToHorizontalBox(root)
        slot:SetPadding({Left=0,Top=10,Right=10,Bottom=0})
        slot:SetVerticalAlignment(2)
        self.buttons[#self.buttons+1]={widget=root,action=action,pressed=false}
        return caption
    end
    function self:mountPanel(menu)
        local canvas=menu.PlayerMenu
        clean(canvas)
        local box=Umg.Construct('/Script/UMG.VerticalBox',canvas,name('Panel'))
        local master=addSlider(box,nil,locale:t('native_master'),16)
        local masterSlot=box:AddChildToVerticalBox(master)
        masterSlot:SetHorizontalAlignment(1)
        local actions=Umg.Construct('/Script/UMG.HorizontalBox',box,name('Actions'))
        box:AddChildToVerticalBox(actions)
        button(actions,locale:t('native_report'),handlers.report)
        button(actions,locale:t('native_support'),handlers.donate)
        local micCaption=button(actions,'',function() handlers.solo(not state.solo) end)
        local slot=canvas:AddChildToCanvas(box)
        slot:SetAnchors({Minimum={X=.025,Y=.74},Maximum={X=.44,Y=.74}})
        slot:SetOffsets({Left=0,Top=0,Right=0,Bottom=120})
        slot:SetZOrder(5)
        self.panels[menu:GetAddress()]={menu=menu,micCaption=micCaption}
    end
    function self:mountRow(row,key)
        local size=row.WidgetTree.RootWidget
        local overlay=size:GetChildAt(0)
        clean(overlay)
        size:SetHeightOverride(80)
        -- VAlign_Top=1 and VAlign_Bottom=3. Fill stretches the native buttons.
        for i=0,overlay:GetChildrenCount()-1 do
            local child=overlay:GetChildAt(i)
            if child:GetFName():ToString()=='HorizontalBox_1' then child.Slot:SetVerticalAlignment(1) end
        end
        local border=Umg.Construct('/Script/UMG.Border',overlay,name('Row'))
        border:SetBrushColor({R=.008,G=.035,B=.035,A=1})
        border:SetPadding({Left=18,Top=3,Right=12,Bottom=3})
        local isLocal=state.players[key].local_player
        local title=isLocal and locale:t('native_local') or locale:t('native_voice')
        local root,control=addSlider(border,key,title,11)
        border:SetContent(root)
        border:SetHorizontalAlignment(1)
        local slot=overlay:AddChildToOverlay(border)
        slot:SetVerticalAlignment(3)
        slot:SetPadding({Left=0,Top=0,Right=0,Bottom=0})
        local old=self.rows[row:GetAddress()]
        if old then old.control.retired=true end
        self.rows[row:GetAddress()]={row=row,key=key,control=control}
    end
    function self:refresh()
        if language~=locale.language then
            language=locale.language
            for _,control in ipairs(self.controls) do control.retired=true end
            self.panels,self.rows={},{ }
        end
        for address,panel in pairs(self.panels) do
            if not valid(panel.menu) then self.panels[address]=nil end
        end
        for address,entry in pairs(self.rows) do
            if not M.isPlayerRow(entry.row) then entry.control.retired=true;self.rows[address]=nil end
        end
        for _,menu in pairs(FindAllOf('W_PlayerMenu_C') or {}) do
            if valid(menu) and menu:GetFullName():find('/Engine/Transient',1,true) and not self.panels[menu:GetAddress()] then
                self:mountPanel(menu)
            end
        end
        for _,row in pairs(FindAllOf('W_HUD_PlayerListRow_C') or {}) do
            if M.isPlayerRow(row) then
                local key=row.PlayerState:GetFName():ToString()
                local old=self.rows[row:GetAddress()]
                if state.players[key] and (not old or old.key~=key) then self:mountRow(row,key) end
            end
        end
        for i=#self.controls,1,-1 do
            local control=self.controls[i]
            if control.retired or not valid(control.slider) then table.remove(self.controls,i)
            else
                local value=control.key and (state.levels[control.key] or 1) or state.master
                if math.abs(value-control.last)>.0001 then Slider.apply(control,value) end
                local player=control.key and state.players[control.key]
                control.slider:SetIsEnabled(not control.key or (player~=nil and (not player.local_player or state.solo)))
            end
        end
        for _,panel in pairs(self.panels) do
            Umg.SetLabelText(panel.micCaption,locale:t('native_solo',locale:t(state.solo and 'on' or 'off')))
        end
        for i=#self.buttons,1,-1 do
            if not valid(self.buttons[i].widget) then table.remove(self.buttons,i) end
        end
    end
    function self:poll()
        for _,control in ipairs(self.controls) do
            if valid(control.slider) and (not control.key or state.players[control.key]) then Slider.poll(control) end
        end
        for _,control in ipairs(self.buttons) do
            if valid(control.widget) then
                local pressed=control.widget:IsPressed()
                if pressed and not control.pressed then control.action() end
                control.pressed=pressed
            end
        end
    end
    return self
end
return M
