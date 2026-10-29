-- Extend the game's own microphone control without changing its selected value,
-- percentage conversion, persistence or native voice callbacks.
local M={MAX_PERCENT=1000}
local TABLE='/Game/Blueprints/DataTables/Settings/DT_AudioSettings.DT_AudioSettings'
local function valid(o) return o~=nil and o:IsValid() end
local function extend(settings)
    settings.MaxSliderValue=math.max(settings.MaxSliderValue,M.MAX_PERCENT)
    return settings.MaxSliderValue
end
function M.refresh()
    local table=StaticFindObject(TABLE)
    if valid(table) then
        local row=table:FindRow('MicrophoneVolume')
        if row then extend(row.SliderSettings) end
    end
    for _,widget in pairs(FindAllOf('StyledSliderSetting_C') or {}) do
        if valid(widget) and widget:GetFullName():find('/Engine/Transient',1,true)
            and widget.CVarName:ToString()=='GameAudio.VOIPInput' and valid(widget.Slider) then
            local limit=extend(widget.SliderSettings)
            widget.MaxSliderValue=limit
            if widget.Slider:GetMaxValue()<limit then widget.Slider:SetMaxValue(limit) end
            if widget.Slider:GetMaxSliderValue()<limit then widget.Slider:SetMaxSliderValue(limit) end
        end
    end
    local api=StaticFindObject('/Script/UniversalVoiceChatPro.Default__UniversalVoiceChat')
    if valid(api) then
        local actor=api:VoiceChatGetMyLocalPlayerVoiceChat()
        if valid(actor) then
            local value=actor.voiceVolume
            if type(value)=='number' and value==value and value>=0 and value<math.huge then
                -- Beyond the old 400% limit (400 * .02 = 8), the native volume
                -- setter added no measured gain. Apply that excess through raw
                -- microphone gain; receiver/master levels stay separate.
                api:VoiceChatSetRawMicrophoneGain(math.max(1,value/8))
            end
        end
    end
end
return M
