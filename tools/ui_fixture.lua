-- Local developer preview: real UMG rows, no PlayerState or network actors.
local Helpers=require('UEHelpers.UEHelpers')
local Util=require('ModMenu.core.util')
local NativeUI=require('native_ui')
local State=require('state')
local Umg=require('ModMenu.core.umg')
local M={}
local PREFIX='HearYourFriends_Preview_'
local function valid(o) return o~=nil and o:IsValid() end
function M.clear()
    for _,row in pairs(FindAllOf('W_HUD_PlayerListRow_C') or {}) do
        if valid(row) then
            pcall(function()
                local overlay=NativeUI.rowOverlay(row)
                if not valid(overlay) then return end
                for i=0,overlay:GetChildrenCount()-1 do
                    if overlay:GetChildAt(i):GetFName():ToString():sub(1,#PREFIX)==PREFIX then
                        row:RemoveFromParent();break
                    end
                end
            end)
        end
    end
    for _,menu in pairs(FindAllOf('W_PlayerMenu_C') or {}) do
        if valid(menu) then
            local canvas=menu.PlayerMenu
            for i=valid(canvas) and canvas:GetChildrenCount()-1 or -1,0,-1 do
                local child=canvas:GetChildAt(i)
                if child:GetFName():ToString():sub(1,#PREFIX)==PREFIX then child:RemoveFromParent() end
            end
        end
    end
end
function M.start(hostState,locale,tag)
    print('[HearYourFriends.Preview] Preview setup waiting for Players UI.\n')
    local state=State.new({gain=hostState.master})
    local ui,menu,scroll
    local previews={
        {key='quiet',name='PREVIEW · Quiet friend',ping='42',buttons={'Profile','Mute','Report','Block'}},
        {key='host',name='PREVIEW · A_very_long_player_name_0123456789',ping='120',buttons={'Profile','Mute','Report','Block','Kick','Ban'}},
        {key='unicode',name='PREVIEW · 玩家 · プレイヤー',ping='999',buttons={'Profile','Mute'}},
        {key='fourth',name='PREVIEW · Fourth player',ping='8',buttons={'Profile','Mute','Report','Block'}},
        {key='fifth',name='PREVIEW · Fifth player',ping='36',buttons={'Profile','Mute','Report','Block'}},
    }
    for _,player in ipairs(previews) do player.local_player=false end
    state:sync(previews)
    local handlers={player=function(key,value)
        state:setPlayer(key,value)
        print(string.format('[HearYourFriends.Preview] %s level=%.2f effective=%.2f\n',key,value,state:effective(key)))
    end}
    local function mount()
        local example
        for _,row in pairs(FindAllOf('W_HUD_PlayerListRow_C') or {}) do
            if NativeUI.isPlayerRow(row) then example=row;break end
        end
        if not example then return false end
        for _,candidate in pairs(FindAllOf('W_PlayerMenu_C') or {}) do
            if valid(candidate) and candidate:GetFullName():find('/Engine/Transient',1,true) then menu=candidate;break end
        end
        if not menu then return false end
        scroll=Umg.Construct('/Script/UMG.ScrollBox',menu.PlayerMenu,PREFIX..tag)
        local slot=menu.PlayerMenu:AddChildToCanvas(scroll)
        slot:SetAnchors({Minimum={X=.026,Y=.35},Maximum={X=.434,Y=.694}})
        slot:SetOffsets({Left=0,Top=0,Right=0,Bottom=0})
        slot:SetZOrder(10)
        local library=StaticFindObject('/Script/UMG.Default__WidgetBlueprintLibrary')
        ui=NativeUI.new(state,handlers,tag..'_Preview',locale)
        for _,player in ipairs(previews) do
            local row=library:Create(Helpers.GetWorld(),example:GetClass(),Helpers.GetPlayerController())
            -- Never run the real row's player-state polling on an unbound preview.
            -- Set before Slate construction; EWidgetTickFrequency::Never = 0.
            row.TickFrequency=0
            local overlay=row.WidgetTree.RootWidget:GetChildAt(0)
            overlay:AddChildToOverlay(Umg.Construct('/Script/UMG.Spacer',overlay,PREFIX..player.key))
            local rowSlot=scroll:AddChild(row)
            row:StopAnimationsAndLatentActions()
            rowSlot:SetHorizontalAlignment(0)
            row:SetVisibility(0)
            player.widget=row
            row.Name:SetText(FText(player.name))
            row.UniquePlayerID:SetText(FText('TEST'))
            row.StatusText:SetText(FText(player.ping))
            -- Native actions are presentation only, including keyboard/controller input.
            local actions=row.WidgetTree.RootWidget:GetChildAt(0)
            for i=0,actions:GetChildrenCount()-1 do
                local child=actions:GetChildAt(i)
                if child:GetFName():ToString()=='HorizontalBox_1' then child:SetVisibility(3) end
            end
            for _,suffix in ipairs({'HardcoreRevive','Profile','Mute','Report','Block','Kick','Ban'}) do
                local button=row['Button_'..suffix]
                button:SetIsEnabled(false)
                button:SetVisibility(1)
            end
            for _,suffix in ipairs(player.buttons) do row['Button_'..suffix]:SetVisibility(0) end
            ui:mountRow(row,player.key)
        end
        print('[HearYourFriends.Preview] Five local UI preview rows added. No network players created.\n')
        return true
    end
    local ticks,lastError=0
    LoopInGameThreadWithDelay(50,Util.PinFn(function()
        local ok,err=pcall(function()
            if ui and not valid(menu) then ui=nil end
            if not ui then mount();return end
            local count=0
            for _ in pairs(hostState.players) do count=count+1 end
            scroll:SetVisibility(count>1 and 1 or 0)
            state.master=hostState.master
            ticks=ticks+1
            if ticks%5==0 then
                for _,player in ipairs(previews) do
                    local row=player.widget
                    row.Name:SetText(FText(player.name))
                    row.Name:SetVisibility(0)
                    local container=row.Name:GetParent()
                    container:SetVisibility(3)
                    container.Slot:SetSize({SizeRule=1,Value=1})
                    for _,suffix in ipairs({'HardcoreRevive','Profile','Mute','Report','Block','Kick','Ban'}) do
                        row['Button_'..suffix]:SetIsEnabled(false)
                        row['Button_'..suffix]:SetVisibility(1)
                    end
                    for _,suffix in ipairs(player.buttons) do row['Button_'..suffix]:SetVisibility(0) end
                end
            end
            if ticks==20 then
                print('[HearYourFriends.Preview] menu='..menu:GetFullName()..' visibility='..tostring(menu:GetVisibility())..' preview_children='..scroll:GetChildrenCount()..'\n')
                local slate=StaticFindObject('/Script/UMG.Default__SlateBlueprintLibrary')
                for _,player in ipairs(previews) do
                    local row=player.widget
                    print('[HearYourFriends.Preview] '..player.key..' visibility='..tostring(row:GetVisibility())..' attached='..tostring(valid(row:GetParent()))..' desired='..tostring(row:GetDesiredSize().Y)..'\n')
                    pcall(function()
                        local geometry=row:GetCachedGeometry()
                        local origin=slate:LocalToAbsolute(geometry,{X=0,Y=0})
                        local size=slate:GetAbsoluteSize(geometry)
                        print(string.format('[HearYourFriends.Preview.Layout] %s x=%.1f y=%.1f w=%.1f h=%.1f\n',player.key,origin.X,origin.Y,size.X,size.Y))
                    end)
                end
            end
            if ticks%5==0 then ui:refreshRows() end
            ui:poll()
        end)
        if not ok and tostring(err)~=lastError then
            lastError=tostring(err)
            print('[HearYourFriends.Preview] '..lastError..'\n')
        elseif ok then lastError=nil end
    end))
end
return M
