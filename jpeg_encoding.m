
clear all;
close all;

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
%{

Q_table1 = ones(4,4);
Q_table2 = 16*ones(4,4);
Q_table3 = 64*ones(4,4);
Q_table = [Q_table1 Q_table2; Q_table2 Q_table3];
%}
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

img_s = size(X_in);
block_s = 8;
blockx = img_s(1)/8;
blocky = img_s(2)/8;
img_RLC = [];
for i=0:(blockx-1)
    for j=0:(blockx-1)
        y = A*X_in(i*8+1:(i+1)*8, j*8+1:(j+1)*8)*B; %DCT
        idx_mat = round(y./Q_table); %Quantization
        
        mat_s = size(idx_mat); %Zigzag scan into 1*64 vector
        for k=1:(mat_s(1)*mat_s(2)) 
            idx_vec(k) = idx_mat(ZZ(k,1), ZZ(k,2));
        end
        
        zero_cnt = 0; %Run-Length Coding
        RLC_mat = [];
        for k=1:length(idx_vec)
            if k==1
                RLC_mat(k,1) = 0;
                RLC_mat(k,2) = idx_vec(k);
            else
                if idx_vec(k)==0
                    zero_cnt = zero_cnt + 1;
                else
                    RLC_mat = [RLC_mat; zero_cnt idx_vec(k)];
                    zero_cnt = 0;
                end
            end
        end
        RLC_mat = [RLC_mat; 0 0];
        block_RLC = num2cell(RLC_mat,2); %RLC_mat into cell format
        
        img_RLC = [img_RLC; block_RLC]; %collect all symbols for all 1024 blocks
    end
end    

symb_cnt(1) = 1; %count the frequency of each symbols
symb(1) = img_RLC(1);
flag = 0;
for i=2:length(img_RLC) 
    for j=1:length(symb)
        flag = cellfun(@isequal, img_RLC(i), symb(j));
        if flag
            symb_cnt(j) = symb_cnt(j) + 1;
            break
        end
    end
    if flag==0
        symb = [symb img_RLC(i)];
        symb_cnt = [symb_cnt 1]; 
    end
end
symb_pro = symb_cnt/sum(symb_cnt);

[dict,avglen] = huffmandict(symb,symb_pro); %Huffman coding

img_code = []; %Encoding the whole image 
for i=1:length(img_RLC)
    for j=1:length(dict)
        flag = isequal(dict{j,1},img_RLC{i});
        if flag
            dict_idx = j;
            break
        end
    end
    img_code = [img_code dict{j,2}];
end

fid = fopen('cool.abc', 'w');
fwrite(fid, img_code);