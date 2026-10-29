local ModMenu=require('ModMenu.ModMenu')
local Helpers=require('UEHelpers.UEHelpers')
local Util=require('ModMenu.core.util')
local config=require('config')
local Playback=require('playback')
local Players=require('players')
local Slider=require('slider')
local NativeUI=require('native_ui')
local Report=require('report')
local MenuReload=require('menu_reload')
local state=require('state').new(config)
local locale=require('i18n').new(function()
    local library=StaticFindObject('/Script/Engine.Default__KismetInternationalizationLibrary')
    return Util.ToPlainString(library:GetCurrentLanguage())
end)
locale:refresh()
local roster,events,context={},{},{}
local localActor,world,lastRoster,lastStatus
local prepared=false
local failures={}
local native
local function valid(object) return object~=nil and object:IsValid() end
local function status(message)
    if message==lastStatus then return end
    lastStatus=message
    ModMenu.SetLabel('Voice','status',message)
    print('[HearYourFriends] '..message..'\n')
end
local function event(kind,value,key,failure)
    local player=key and state.players[key]
    local message=failure and tostring(failure):match('([^\\/]+%.lua:%d+:[^\r\n]*)') or (failure and tostring(failure):match('^[^\r\n]*'))
    if failure then
        if failures[kind]==message then return end
        failures[kind]=message
        print('[HearYourFriends.Error] '..tostring(message)..'\n')
    end
    events[#events+1]={time=os.date('!%H:%M:%S'),kind=kind,value=value,player=player and player.slot,
        error=message and tostring(message):sub(1,240)}
    if #events>32 then table.remove(events,1) end
end
local function apply()
    local healthy,monitorReady=true,false
    for _,player in ipairs(roster) do
        local ok,failure=pcall(function()
            local actor=player.actor
            if not valid(actor) or (not player.local_player and player.muted) then return end
            local mic=actor.microphoneSpeakComponent
            if not valid(mic) then return end
            local audio=mic.VoiceCaptureAudioComponent
            if not valid(audio) or not valid(audio.Sound) then return end
            if player.local_player then monitorReady=true end
            if player.local_player and not state.solo and not Playback.managed(mic) then return end
            local gain=player.local_player and not state.solo and 1 or state:effective(player.key)
            local db=Playback.apply(mic,actor.voiceVolume,gain)
            if config.diagnostics and player.local_player then
                print(string.format('[HearYourFriends.Measure] gain=%.6f base=%.6f effect_db=%.6f\n',gain,actor.voiceVolume,db or 0))
            end
        end)
        if not ok then
            healthy=false
            event('voice_error',nil,player.key,failure)
            status(locale:t('voice_error'))
        end
    end
    return healthy,monitorReady
end
local handlers={}
function handlers.master(value)
    local previous=state.master;state:setMaster(value)
    ModMenu.Set('Voice','gain',state.master)
    if previous~=state.master then event('master',state.master);apply() end
end
function handlers.player(key,value)
    local previous=state.levels[key] or 1;state:setPlayer(key,value)
    ModMenu.Set('Players',key,state.levels[key] or 1)
    if previous~=(state.levels[key] or 1) then event('player_level',state.levels[key],key);apply() end
end
function handlers.solo(value)
    state.solo=value==true;ModMenu.Set('Voice','solo',state.solo);event('solo',state.solo);apply()
end
local function launch(url)
    StaticFindObject('/Script/Engine.Default__KismetSystemLibrary'):LaunchURL(url)
end
function handlers.donate() launch('https://ko-fi.com/utof') end
local function capture()
    local system=StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
    pcall(function() context.engine=Util.ToPlainString(system:GetEngineVersion()) end)
    pcall(function() context.game_build=Util.ToPlainString(system:GetBuildVersion()) end)
    pcall(function() context.loader=string.format('%s.%s.%s',UE4SS.GetVersion()) end)
    pcall(function() context.role=localActor:HasAuthority() and 'host' or 'client' end)
    pcall(function() context.map=Helpers.GetWorld():GetFName():ToString() end)
    context.language=locale.language
    context.players=Players.diagnostics(roster,localActor)
    return Report.capture(state,context,events)
end
function handlers.report()
    local data=capture()
    local path,failure=Report.save(data)
    if path then status(locale:t('report_saved'))
    else event('report_error',nil,nil,failure);status(locale:t('report_failed')) end
    launch(Report.issueUrl(data))
end
Slider.install()
ModMenu.Init({title='Hear Your Friends',key=Key.F8,keyHint='F8',ignoreLook=true})
local function registerVoice()
    ModMenu.Register({id='Voice',title=locale:t('voice_title'),items={
        {type='slider',id='gain',label=locale:t('master'),default=state.master,onChange=handlers.master},
        {type='checkbox',id='solo',label=locale:t('solo_test'),default=state.solo,onChange=handlers.solo},
        {type='label',id='status',label=locale:t('load_world')},
        {type='label',label=locale:t('range_hint')},
        {type='button',id='report',label=locale:t('report'),onClick=handlers.report},
        {type='button',id='donate',label=locale:t('support'),variant='warning',onClick=handlers.donate},
    }})
end
registerVoice()
native=NativeUI.new(state,handlers,ModMenu.GetInstanceId(),locale)
local function update()
    local ok,failure=pcall(function()
        if locale:refresh() then registerVoice();lastRoster=nil;lastStatus=nil end
        if not prepared then MenuReload.prepare(ModMenu.GetInstanceId());prepared=true end
        local api=StaticFindObject('/Script/UniversalVoiceChatPro.Default__UniversalVoiceChat')
        if not valid(api) then status(locale:t('waiting_voice'));return end
        localActor=api:VoiceChatGetMyLocalPlayerVoiceChat()
        if not valid(localActor) then status(locale:t('load_world'));return end
        local game=Helpers.GetGameStateBase()
        if not valid(game) then return end
        local current=Helpers.GetWorld():GetAddress()
        if world and world~=current then state:sync({});lastRoster=nil end
        world=current
        roster,context.mute_all=Players.collect(api,localActor,game.PlayerArray,FindAllOf('PlayerVoiceChatActor') or {})
        state:sync(roster)
        local signature={}
        for _,player in ipairs(roster) do signature[#signature+1]=player.key..':'..player.name end
        signature=table.concat(signature,'|')
        if signature~=lastRoster then
            local items={}
            for _,player in ipairs(roster) do
                if not player.local_player then
                    local key=player.key
                    items[#items+1]={type='slider',id=key,label=player.name,default=state.levels[key] or 1,
                        onChange=function(value) handlers.player(key,value) end}
                end
            end
            if #items==0 then items[1]={type='label',label=locale:t('no_players')} end
            ModMenu.Register({id='Players',title=locale:t('players_title'),items=items})
            for _,player in ipairs(roster) do
                if not player.local_player then ModMenu.Set('Players',player.key,state.levels[player.key] or 1) end
            end
            lastRoster=signature
        end
        local healthy,monitorReady=apply()
        native:refresh(monitorReady)
        if not healthy then return end
        if state.solo then
            status(monitorReady and locale:t('monitor_active',state.master) or locale:t('monitor_pending'))
        else status(locale:t('ready')) end
    end)
    if not ok then event('update_error',nil,nil,failure);status(locale:t('controls_error')) end
end
LoopInGameThreadWithDelay(500,Util.PinFn(update))
LoopInGameThreadWithDelay(16,Util.PinFn(function()
    local ok,failure=pcall(function() native:poll() end)
    if not ok then event('ui_error',nil,nil,failure) end
end))
print(string.format('[HearYourFriends] Loaded: gain=%.3f solo=%s; F8 controls.\n',state.master,tostring(state.solo)))
