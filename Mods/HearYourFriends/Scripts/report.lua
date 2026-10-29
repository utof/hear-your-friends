local Json=require('ModMenu.store.json')
local M={VERSION='0.2.0-alpha.1'}
local source=debug.getinfo(1,'S').source
local directory=source:sub(2):match('^(.*[\\/])') or './'
local function diagnosticNumber(value)
    if type(value)~='number' then return value end
    if value~=value then return 'NaN' end
    if value==math.huge then return '+Infinity' end
    if value==-math.huge then return '-Infinity' end
    return value
end
function M.encodeUrl(text)
    return (text:gsub('([^%w%-_%.~])',function(c) return string.format('%%%02X',string.byte(c)) end))
end
function M.capture(state,context,events)
    local data={schema=1,mod_version=M.VERSION,created_utc=os.date('!%Y-%m-%dT%H:%M:%SZ'),
        game_build=context.game_build,engine=context.engine,loader=context.loader,role=context.role,
        map=context.map,language=context.language,master=state.master,solo=state.solo,mute_all=context.mute_all,
        update_ms=500,players={},events={}}
    for index,player in ipairs(context.players or {}) do
        data.players[index]={id='P'..index,level=state.levels[player.key] or 1,effective=state:effective(player.key),
            baseline=diagnosticNumber(player.baseline),muted=player.muted,local_player=player.local_player,
            voice_ready=player.voice_ready,distance_m=diagnosticNumber(player.distance_m),radio=player.radio,
            component_volume=diagnosticNumber(player.component_volume),base_effect_db=diagnosticNumber(player.base_effect_db),radio_effect_db=diagnosticNumber(player.radio_effect_db)}
    end
    for i=math.max(1,#events-31),#events do
        local event=events[i]
        data.events[#data.events+1]={time=event.time,kind=event.kind,value=event.value,player=event.player,error=event.error}
    end
    return data
end
function M.issueUrl(data)
    local details=Json.Encode(data)
    if #details>4500 then
        details=Json.Encode({mod_version=data.mod_version,game_build=data.game_build,engine=data.engine,
            loader=data.loader,master=data.master,solo=data.solo,player_count=#data.players})
    end
    local body='## What happened?\n\n## Steps to reproduce\n1. \n\n## Expected result\n\n## Diagnostics\n```json\n'..details..'\n```\n\nAttach HearYourFriends-report.json from the mod Scripts folder for the full report.\n'
    return 'https://github.com/utof/hear-your-friends/issues/new?title=Voice%20volume%20bug&body='..M.encodeUrl(body)
end
function M.save(data)
    local path=directory..'HearYourFriends-report.json'
    local file,_,code=io.open(path,'w')
    if not file then return nil,'report_open_failed: errno '..tostring(code or 'unknown') end
    local written,_,writeCode=file:write(Json.Encode(data)..'\n')
    local closed,_,closeCode=file:close()
    if not written then return nil,'report_write_failed: errno '..tostring(writeCode or 'unknown') end
    if not closed then return nil,'report_close_failed: errno '..tostring(closeCode or 'unknown') end
    return path
end
return M
