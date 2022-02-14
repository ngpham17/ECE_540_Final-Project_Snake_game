img_file = 'start_screen.jpg';
img = imread(img_file);
img = imresize ((img),[480 640]);
img_g = rgb2gray(img);

img_12 = uint8(double(img_g)/255.0*15.0);

%img_12 = uint8(double(img_g)/255.0*15.0);

img_24 = img_12/15*255;
imshow(img_24);
%di = size (img_12);
% 
% img_24 = uint8(double(img_12)/15*255);
% imshow(img_24);

% row = di(1);
% col = di(2);
%"wt" output a larger txt file than "w"
%due to the limit in memory, need the .mem file as small as possible
%otherwise implementation will be errorred out at 
di = size(img_12);
height = di(1);
width = di(2);
fout = fopen('start_screen_gray_1.coe','w');
fprintf(fout,'memory_initialization_radix=16;\n');
fprintf(fout,'memory_initialization_vector=\n');
% for i=1:row
%     for j=1:col
%         fprintf(fout, '%x', img_12(i,j,:));
%         fprintf(fout, '\n');
%     end
% end
n = 0;
for i = 1:height
    for k = 1:width
        n = n+1;
        fprintf (fout, '0%x', img_12(i,k));
        if (i == (height) && k == (width))
            fprintf(fout, ';');  %end of file
        else
            fprintf(fout, ','); %continue write to the same line
        end
        if ((mod(n, 32)) == 0)
            fprintf(fout,'\n');  %new line after 32 values
        end
    end
end     
  
%fprintf(fout, '0%x,\n', img_12);
fclose('all');
