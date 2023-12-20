function dotfixrefocus = dotfixfocus(R,G,B)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
cgpencol(R,G,B)
%cgmakesprite(255,12,12)
%cgsetsprite(255)
hgt = 10;
wid = 10;
cgrect(0,0,hgt,wid)
%cgrect(xpos-1,ypos,hgt-2,wid)
%cgsetsprite(0)
%cgdrawsprite(255,xpos,ypos,20,20)
%cgrotatesprite(255,xpos,ypos,45)
end

