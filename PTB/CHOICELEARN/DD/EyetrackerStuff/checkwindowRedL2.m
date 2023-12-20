function [Hit,EyePosition] = checkwindowRedL2(xpos,ypos,windowsize,CentreFixation)

%Checks whether eyes are in a window, defined by a centre point and a
%diameter in pixels
%Hit = 0 if OUT and 1 if IN
newsample = 0;
while ~newsample
    if Eyelink('NewFloatSampleAvailable') > 0
        newsample = 1;
        evt = Eyelink('NewestFloatSample');
        EyePosition=(([evt.gx(1) evt.gy(1)]-CentreFixation).*[1 -1]);
        %position of eyes relative to target window
        EyetoTarget = EyePosition-[xpos ypos];
        Hit = ~(norm(EyetoTarget) > windowsize);
    end
end

return