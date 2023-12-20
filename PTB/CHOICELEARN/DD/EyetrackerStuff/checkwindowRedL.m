function [Hit,Blink] = checkwindowRedL(xpos,ypos,windowsize,CentreFixation,LReye)

%Checks whether eyes are in a window, defined by a centre point and a
%diameter in pixels
%Hit = 0 if OUT and 1 if IN
newsample = 0;
Blink = 0;
while ~newsample
    if Eyelink('NewFloatSampleAvailable') > 0
        newsample = 1;
        evt = Eyelink('NewestFloatSample');
         EyePosition=(([evt.gx(LReye) evt.gy(LReye)]-CentreFixation).*[1 -1]);
        %position of eyes relative to target window
        EyetoTarget = EyePosition-[xpos ypos];
        Hit = ~(norm(EyetoTarget) > windowsize);
        if evt.pa == 0
            Blink = 1;
        else
            Blink = 0;
        end
    end
end

return