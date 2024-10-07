function dotfixpv(dotcol,doton)

if doton
    %Fixation dot color
    if dotcol == 1  %red
        red = 1;
        green = 0;
        blue = 0;
    elseif dotcol == 2  %green
        red = 0;
        green = 1;
        blue = 0;
    elseif dotcol == 3  %blue
        red = 0;
        green = 0;
        blue = 1;
    elseif dotcol == 4  %yellow
        red = 1;
        green = 1;
        blue = 0;
    elseif dotcol == 5
        red = 0;
        green = 0;
        blue = 0;
    end

    %UNTITLED Summary of this function goes here
    %   Detailed explanation goes here
    cgpencol(red,green,blue)
    %cgmakesprite(255,12,12)
    %cgsetsprite(255)
    hgt = 12;
    wid = 12;
    cgrect(0,0,hgt,wid)
    %cgrect(xpos-1,ypos,hgt-2,wid)
    %cgsetsprite(0)
    %cgdrawsprite(255,xpos,ypos,20,20)
    %cgrotatesprite(255,xpos,ypos,45)
end


return
