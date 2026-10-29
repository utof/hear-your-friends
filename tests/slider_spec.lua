local existing={type='number'}
package.preload['ModMenu.widgets.init']=function() return {get=function() return existing end,has=function() return false end} end
local widgets=require('ModMenu.widgets.init')
local kinds={}
local umg={}
function umg.Construct(kind)
 kinds[#kinds+1]=kind
 local w={value=0}
 function w:AddChildToVerticalBox() end
 function w:SetMinValue(v) self.min=v end
 function w:SetMaxValue(v) self.max=v end
 function w:SetStepSize() end
 function w:SetValue(v) self.value=v end
 function w:GetValue() return self.value end
 function w:SetIsEnabled(v) self.enabled=v end
 function w:SetSliderBarColor() end
 function w:SetSliderHandleColor() end
 return w
end
umg.StyleText=function() end
umg.SetLabelText=function(w,s) w.text=s end
local module=assert(loadfile('Mods/HearYourFriends/Scripts/slider.lua'),'slider module missing')()
local changed
local root,control=module.create(umg,{},'test','Master voice',1,function(v) changed=v end,18)
assert(control.slider.min==0 and control.slider.max==4, 'real slider exposes zero through four')
control.slider.value=2.126
module.poll(control)
assert(changed==2.15 and control.label.text:find('2.15',1,true), 'drag updates numeric readout and callback')
changed=nil
module.apply(control,.5)
module.poll(control)
assert(changed==nil, 'external state synchronization does not emit another change')
module.install()
assert(widgets.get('slider')==module and widgets.get('number')==existing, 'adapter retains existing ModMenu widget types')
print('slider tests passed')
module.apply(control,0)
module.reset(control)
assert(control.last==1 and control.slider.value==1 and changed==1, 'Reset restores normal gain and applies it immediately')
