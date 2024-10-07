function dotfixleft = dotfixl(R,G,B)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
xpoly = [0 0 -10];
ypoly = [8 -8 0];
cgpencol(R,G,B)
cgfont('Arial',30)
%cgmakesprite(255,12,12)
%cgsetsprite(255)
hgt = 12;
wid = 12;
cgrect(0,0,hgt,wid);
cgpolygon(xpoly,ypoly,-8,0)
%cgsetsprite(0)
%cgdrawsprite(255,xpos,ypos,20,20)
%cgrotatesprite(255,0,0,225) %For left make it to 45 deg, for Right 225 deg



end

