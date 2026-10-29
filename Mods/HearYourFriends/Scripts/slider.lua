local M={type='slider'}
local function quantize(value)
    return math.max(0,math.min(4,math.floor(value*20+.5)/20))
end
local function caption(control,value)
    control.umg.SetLabelText(control.label,control.inline and control.caption or string.format('%s  %.2f×',control.caption,value))
    if control.readout then control.umg.SetLabelText(control.readout,string.format('%.2f×',value)) end
end
function M.refreshCaption(control) caption(control,control.last) end
function M.create(umg,parent,name,label,value,onChange,font,inline)
    local root=umg.Construct(inline and '/Script/UMG.HorizontalBox' or '/Script/UMG.VerticalBox',parent,name)
    local text=umg.Construct('/Script/UMG.TextBlock',root,name..'_Text')
    umg.StyleText(text,font or 18,{R=.6,G=1,B=1,A=1})
    if inline then
        local slot=root:AddChildToHorizontalBox(text)
        slot:SetVerticalAlignment(2)
        slot:SetPadding({Left=0,Top=0,Right=12,Bottom=0})
    else root:AddChildToVerticalBox(text) end
    local slider=umg.Construct('/Script/UMG.Slider',root,name..'_Slider')
    -- Set the style before Slate creates the widget (5.4 has no reflected setter).
    if slider.WidgetStyle then
        slider.WidgetStyle.BarThickness=4
        for _,key in ipairs({'NormalThumbImage','HoveredThumbImage','DisabledThumbImage'}) do
            slider.WidgetStyle[key].ImageSize={X=12,Y=22}
        end
    end
    slider:SetMinValue(0);slider:SetMaxValue(4);slider:SetStepSize(.05)
    slider:SetSliderBarColor({R=.05,G=.4,B=.4,A=1})
    slider:SetSliderHandleColor({R=1,G=.92,B=.25,A=1})
    slider:SetValue(value)
    if inline then
        local slot=root:AddChildToHorizontalBox(slider)
        slot:SetSize({SizeRule=1,Value=1})
        slot:SetVerticalAlignment(2)
    else root:AddChildToVerticalBox(slider) end
    local control={kind='slider',widget=root,slider=slider,label=text,caption=label,inline=inline,last=value,onChange=onChange,umg=umg}
    if inline then
        local box=umg.Construct('/Script/UMG.SizeBox',root,name..'_ValueWidth')
        box:SetWidthOverride(76)
        control.readout=umg.Construct('/Script/UMG.TextBlock',box,name..'_Value')
        umg.StyleText(control.readout,font or 14,{R=.6,G=1,B=1,A=1})
        control.readout:SetJustification(2)
        box:SetContent(control.readout)
        local slot=root:AddChildToHorizontalBox(box)
        slot:SetVerticalAlignment(2)
        slot:SetPadding({Left=12,Top=0,Right=10,Bottom=0})
    end
    caption(control,value)
    return root,control
end
function M.poll(control)
    local value=quantize(control.slider:GetValue())
    if math.abs(value-control.last)>.0001 then
        control.last=value
        caption(control,value)
        control.onChange(value)
    end
end
function M.apply(control,value)
    control.last=value
    control.slider:SetValue(value)
    caption(control,value)
end
function M.reset(control)
    M.apply(control,1)
    control.onChange(1)
end
function M.validate(item)
    assert(item.id and item.label,'slider requires id and label')
end
function M.seed(section,item,values)
    local key=section..'.'..item.id
    if values[key]==nil then values[key]=item.default or 1 end
end
function M.build(ctx)
    local key=ctx.ValueKey(ctx.section.id,ctx.item.id)
    local root,control=M.create(ctx.umg,ctx.contentBox,ctx.namePrefix,ctx.item.label,ctx.values[key] or 1,function(value)
        ctx.values[key]=value
        ctx.SafeCall(ctx.item.onChange,value)
    end,ctx.config.fontItem)
    control.item,control.valueKey,control.sectionId=ctx.item,key,ctx.section.id
    ctx.umg.AddToContent(ctx,root)
    ctx.umg.AddItemPad(ctx,ctx.namePrefix..'_Pad',8)
    table.insert(ctx.liveControls,control)
end
function M.install()
    local widgets=require('ModMenu.widgets.init')
    local get,has=widgets.get,widgets.has
    widgets.get=function(kind) if kind=='slider' then return M end return get(kind) end
    widgets.has=function(kind) return kind=='slider' or has(kind) end
end
return M
