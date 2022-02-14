%makecoe("gameover.mp3",1,80000,1,"gameover.coe",127,8);
function output = makecoe(filename,start,finish,channel,output_name,scaling_factor,bit_width)

disp('Converting data into binary...')


input =  audioread(filename);

%resampled = downsample(input,5);

data = input(start:finish,channel);

scaled_data = data*scaling_factor;
rounded_data = round(scaled_data);

bits_table = dec2bit(rounded_data,bit_width);

disp('done.')
disp(' ')
disp('Formatting output...')

output = addcomma(bits_table);

file = fopen(output_name,'w');
fprintf(file,'memory_initialization_radix=2;\n');
fprintf(file,'memory_initialization_vector=\n');
dlmwrite(output_name,output,'-append','delimiter','', 'newline', 'pc');
disp('done.')

end

% Given a list of integers (input_data), returns them in 
% binary with number of bits specified by (bits).

function output = dec2bit(input_data, bits)

for i = 1:length(input_data)
    
        data(i) = input_data(i)+ 128;
    
end

output = dec2bin(data,bits); %get binary representations

end

% Adds comma to each entry of the data.

function output = addcomma(data)

rowxcolumn = size(data);
rows = rowxcolumn(1);
columns = rowxcolumn(2);

output = data;

for i = 1:(rows-1)
    output(i,(columns+1)) = ',';
end

output(rows,(columns+1)) = ';';

end
