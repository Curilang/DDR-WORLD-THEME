local t = Def.ActorFrame{ GetSoftwareVersion(); };
local xspacing = 40
local curIndex = 1;
local LangItems = { "English", "Japanese", "Korean" };

local function MakeRowItem(LangItems, idx)
    return Def.ActorFrame{
        Name="Item"..idx;
        BeginCommand=function(s) s:playcommand(idx == curIndex and "GainFocus" or "LoseFocus") end,
        MoveScrollerMessageCommand=function(s,p)
            SCREENMAN:SystemMessage(curIndex)
            if curIndex == idx then
				s:playcommand("GainFocus")
			else
				s:playcommand("LoseFocus")
            end
        end,
        Def.ActorFrame{
            Def.Sprite{
                Texture="base",
                InitCommand=function(s) s:pause() end,
                GainFocusCommand=function(s) s:setstate(1) end,
                LoseFocusCommand=function(s) s:setstate(0) end,
            };
            Def.Sprite{
                Texture=THEME:GetPathG("","_shared/line"),
                InitCommand=function(s) s:visible(false):setsize(268,7):y(23):queuecommand("Animate") end,
                GainFocusCommand=function(s) s:visible(true) end,
                AnimateCommand=function(s) s:texcoordvelocity(-0.1,0) end,
                LoseFocusCommand=function(s) s:visible(false) end,
            };
        };
        Def.Sprite{
            Texture=LangItems,
			InitCommand=function(s) s:pause() end,
			GainFocusCommand=function(s) s:setstate(1) end,
			LoseFocusCommand=function(s) s:setstate(0) end,
        };
    };
end

local ItemList = {};
for i=1,#LangItems do
    ItemList[#ItemList+1] = MakeRowItem(LangItems[i],i)
end

local function input(event, param)
    if not event.PlayerNumber or not event.button then
        return false
    end

    if event.type ~= "InputEventType_Release" then
        if  event.GameButton == "Start" then
            ThemePrefs.Set("Language",LangItems[curIndex])
            SOUND:PlayOnce(THEME:GetPathS("common","start"))
            GetLanguage()
            SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
        elseif event.GameButton == "Back" then
            SOUND:StopMusic()
            SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToPrevScreen")
        elseif event.GameButton == "MenuRight" or event.GameButton == "MenuDown" then
            if curIndex >= #LangItems then
                curIndex = #LangItems
            else
                curIndex = curIndex+1
            end
            SOUND:PlayOnce(THEME:GetPathS("common","change"))
        elseif event.GameButton == "MenuLeft" or event.GameButton == "MenuUp" then
            if curIndex == 1 then
                curIndex = 1
            else
                curIndex = curIndex-1
            end
            SOUND:PlayOnce(THEME:GetPathS("common","change"))
        end
        MESSAGEMAN:Broadcast("MoveScroller");
    end
    return false
end

t[#t+1] = Def.ActorFrame{
    InitCommand=function(s) s:Center():queuecommand("Capture") end,
    CaptureCommand=function(s)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
    end,
	Def.ActorScroller{
		InitCommand=function(s) s:zoom(0.667):y(-55) end,
		OffCommand=function(s) s:linear(0.2):zoomy(0) end,
			SecondsPerItem=0;
            NumItemsToDraw=10;
		TransformFunction=function(s,ofc,itemIndex,numItems) s:y((ofc*60)) end,
			children=ItemList;
	};
	Def.Sprite{
		Texture="title",
		InitCommand=function(s) s:y(-105):zoom(0.677) end,
		OffCommand=function(s) s:linear(0.2):zoomy(0) end,
    };
	Def.Sound{
		File=THEME:GetPathS("WORLD/Screen", "Out"),
		OffCommand=function(s) s:play() end,
	};
}

-- the menu timer (Scripts/08 MenuTimer.lua)
t[#t+1] = DDRWORLD_MenuTimer("ScreenSelectLanguage", MenuTimerPositions.Language.x, MenuTimerPositions.Language.y);

return t;