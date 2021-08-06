%img_code = ?????????
%dict = ?????????

N=8;
for u=0:7
    for x=0:7
        if u==0
            alpha=(sqrt(1/N));
        else
            alpha=(sqrt(2/N));
        end
        cos_rst(u+1,x+1)=alpha*cos(((2*x+1)*u*pi)/(2*N));
    end
end
A = cos_rst;
B = cos_rst';

X_in = double(imread('cameraman.tif'));

Q_table=[4 4 4 6 4 40 51 61
        4 8 4 19 6 58 60 55
        4 3 6 4 40 57 69 56
        4 7 2 29 51 87 80 62
        18 22 37 56 68 109 103 77
        24 35 55 64 81 104 113 92
        49 64 78 87 103 121 120 101
        72 92 95 98 112 100 103 99];

ZZ=[1 1;1 2;2 1;3 1;2 2;1 3;1 4;2 3;
    3 2;4 1;5 1;4 2;3 3;2 4;1 5;1 6;
    2 5;3 4;4 3;5 2;6 1;7 1;6 2;5 3;
    4 4;3 5;2 6;1 7;1 8;2 7;3 6;4 5;
    5 4;6 3;7 2;8 1;8 2;7 3;6 4;5 5;
    4 6;3 7;2 8;3 8;4 7;5 6;6 5;7 4;
    8 3;8 4;7 5;6 6;5 7;4 8;5 8;6 7;
    7 6;8 5;8 6;7 7;6 8;7 8;8 7;8 8];


code_len = 1; %Rebuild the Run-Length Coding with codebook and image code
img_RLC_hat = [];
while(length(img_code)>0)
    for i=1:length(dict)
        flag = isequal(dict{i,2},img_code(1:code_len));
        if flag
            img_RLC_hat = [img_RLC_hat; dict{i,1}];
            img_code(1:code_len) = [];
            break
        end
    end
    
    if flag
        code_len = 1;
    else
        code_len = code_len+1;
    end    
end

idx_vec_hat = []; %Rebuild the zigzag vector
img_idx_vec = [];
for i=1:length(img_RLC_hat)
    fill_num = length(idx_vec_hat);
    if img_RLC_hat(i,1)==0
        if img_RLC_hat(i,2)==0
            idx_vec_hat(fill_num+1:64) = 0;
            img_idx_vec = [img_idx_vec; idx_vec_hat];
            idx_vec_hat = [];
        else
            idx_vec_hat = [idx_vec_hat img_RLC_hat(i,2)];
        end
    else
        idx_vec_hat(fill_num+1:fill_num+img_RLC_hat(i,1)) = 0;
        idx_vec_hat = [idx_vec_hat img_RLC_hat(i,2)];
    end
end

block_num = sqrt(length(img_idx_vec)); %Rebuild the whole image
for i=1:block_num
    for j=1:block_num
        block_index = ((i-1)*block_num)+j;
        for k=1:size(img_idx_vec,2)
            idx_mat_hat(ZZ(k,1), ZZ(k,2)) = img_idx_vec(block_index,k); %Rebuild the index matrix
        end
        
        y_hat = idx_mat_hat.*Q_table; %Inverse Quantization
        x_hat((i-1)*8+1:i*8, (j-1)*8+1:j*8) = B*y_hat*A; %Inverse DCT
    end
end

mse = immse(X_in,x_hat);
PSNR = 10*log10(255^2/mse);

figure;
subplot(1,2,1);
imshow(uint8(X_in));
subplot(1,2,2);
imshow(uint8(x_hat));
title(mse);
%xlabel(‘’);
