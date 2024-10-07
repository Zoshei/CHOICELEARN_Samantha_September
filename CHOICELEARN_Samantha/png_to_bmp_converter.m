clear all;

%%
image_dir = 'images\redundant';
files = dir(fullfile(image_dir, '*.png'));

%%
for i = 1:length(files)
    pic_name = fullfile(image_dir, files(i).name);
    pic_name_bmp = [pic_name(1:end-3),'bmp'];
    disp(pic_name)
    disp(pic_name_bmp)
    pic = imread(pic_name);
    imwrite(pic,pic_name_bmp,'bmp');
end

