function [gx,gy,gabor] = ez_gabor_xy_DD(GAB)

%Produces a Gabor of known size, spatial-frequency and oprientation.
%The Gabor is not scaled in anyway and will run from -1 to 1.
%GAB should be a structure containing the following fields:
%GAB.xsize, ysize = size of Gabor in pixels
%GAB.SF = spatial frequency in cycles per degree
%GAB.Pix2Ang = The extent of one pixel in visual degrees (e.g. 1/30)
%GAB.Orient = the orientation (in degrees)
%GAB.sd = standard-deviation of gaussian in visual degrees
%GAB.Phase = phase relative to a cosine (i.e. 0 means white stripe in the
%center, this is teh default)
%GAB.mask (optional): mask out the regions that fall outside the mask
%radius (in degrees)
%Example
% GAB.xsize = 100;
% GAB.ysize = 100;
% GAB.SF = 0;
% GAB.Pix2Ang = 1/30;
% GAB.Orient = 45;
% GAB.sd = 1;
% GAB.Phase =0;
% GAB.mask = 1;
% 
if ~isfield(GAB,'Phase')
    GAB.Phase = 0;
end

%Set up 
% %Set up 
% wDegx = GAB.xsize*GAB.Pix2Ang;  %size of image (in degrees)
% wDegy = GAB.ysize*GAB.Pix2Ang;  %size of image (in degrees)
% xv = linspace(-wDegx/2,wDegx/2,GAB.xsize+1);
% yv = linspace(-wDegy/2,wDegy/2,GAB.ysize+1);
% [x,y] = meshgrid(xv,yv);
% x = x(1:end-1,1:end-1);
% y = y(1:end-1,1:end-1);

xv = 1:GAB.xsize;
yv = 1:GAB.ysize;
xv = (xv-mean(xv)).*GAB.Pix2Ang;
yv = (yv-mean(yv)).*GAB.Pix2Ang;
[x,y] = meshgrid(xv,yv);

%GABing
orientation = GAB.Orient;
ramp = cosd(orientation)*x - sind(orientation)*y;
GABing = cosd(360*GAB.SF*ramp-GAB.Phase);

%Gaussian
%1d
gx = normpdf(x,0,GAB.sd);
gy = normpdf(y,0,GAB.sd);
gaussian = gx.*gy;
gaussian = gaussian./max(max(gaussian));

%Gabor
gabor = GABing.*gaussian;

end
% %Uncomment to visualize
% figure;imagesc(gabor);colorbar;axis square;
