local pn = ({...})[1] --only argument to file
local GR = {
    {0,-80, "Stream"}, --STREAM
    {-82,-34, "Voltage"}, --VOLTAGE
    {-68,32, "Air"}, --AIR
    {68,32, "Freeze"}, --FREEZE
    {82,-34, "Chaos"}, --CHAOS
};

local t = Def.ActorFrame{};

for i,v in ipairs(GR) do
    t[#t+1] = Def.ActorFrame{
        OnCommand=function(s) s:xy(v[1],v[2]) end,
        Def.Sprite{
			Texture="items",
			OnCommand=function(s) s:animate(0):setstate(i-1):y(2) end,
		};
        Def.BitmapText{
            Font="_swis721 blk bt","28px";
            InitCommand=function(s) s:xy(0,20):halign(0.5):shadowlength(2) end,
			SetCommand=function(s)
                local song = GAMESTATE:GetCurrentSong();
                    if song then
                        local steps = GAMESTATE:GetCurrentSteps(pn)
                        local value = lookup_ddr_radar_values(song, steps, pn)[i]
                        s:settext(math.floor(value*100+0.5))
                    else
                        s:settext("0")
                    end
            end,
            CurrentSongChangedMessageCommand=function(s) s:queuecommand("Set") end,
            ["CurrentSteps"..ToEnumShortString(pn).."ChangedMessageCommand"]=function(s) s:queuecommand("Set") end,
            ["CurrentTrail"..ToEnumShortString(pn).."ChangedMessageCommand"]=function(s) s:queuecommand("Set") end,
        };
    };
end

return Def.ActorFrame{
	
	
	Def.Sprite{
		Texture="base",
		InitCommand=function(s) s:zoom(0.595) end,
	};
	Def.ActorFrame{
		InitCommand=function(s) s:xy(-5,3):zoom(0.55) end,
		Def.Sprite{
			Texture="circle",
		};
		t;
		create_ddr_groove_radar("radar",0,0,pn,120,color("#02f5b2"),{color("#02f5b2"),color("#02f5b2"),color("#02f5b2"),color("#02f5b2"),color("#02f5b2")}, "accelerate", 0.133)..{
			InitCommand=function(s) s:diffusealpha(0.75) end,
		};
	};
};
