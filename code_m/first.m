im = imread('1.jpg');
im = im(:,1:300);
im = im2double(im);
object_mask = ones(size(im));
if ~exist('levels')            %%最大的阶数  
    levels = 4;
end
if ~exist('floors')         %%每一阶最大的层数
    floors = 2;
end

if( (min(im(:)) < 0) | (max(im(:)) > 1) )
    fprintf( 2, 'Warning: image not normalized to [0,1].\n' );  
end

fprintf( 2, 'Doubling image size for first octave...\n' );

tic;
% sigma = input('Initial sigma value for doubling image:');%0.5
sigma = 0.5;
signal = im;
if sigma > 0
    g_f = gaussian_f(sigma); %Gaussian Filter
    signal = conv2(im, g_f, 'same');
end

[X, Y] = meshgrid(1:0.5:size(signal, 2), 1:0.5:size(signal,1));
signal = interp2(signal, X, Y, 'linear');
subsample = [0.5];%降采样率

fprintf( 2, 'Prebluring image...\n' );

preblur_sigma = sqrt(sqrt(2)^2-(2*sigma)^2);
if preblur_sigma==0
    Gaussian_p{1,1}=signal;
else
    g_f = gaussian_f(preblur_sigma);
    Gaussian_p{1,1} = conv2(signal, g_f, 'same');
end
clear signal
pre_time = toc;
fprintf( 2, 'Preprocessing time %.2f seconds.\n', pre_time );

initial_sigma = sqrt((2*sigma)^2+preblur_sigma^2);%第一层第一阶sigma
container_sigma = zeros(levels, floors+3);
container_sigma(1,1) = initial_sigma * subsample(1);

filter_size = zeros(levels, floors+3);
filter_sigma = zeros(levels, floors+3);

tic;
for i=1:levels
    sigma = initial_sigma;
    g_f = gaussian_f(sigma);
    filter_size(i, 1) = length(g_f);
    filter_sigma(i, 1) = sigma;
    DOG_p{i} = zeros(size(Gaussian_p{i, 1}, 1), size(Gaussian_p{i, 1}, 2), floors+2);
    for j=2:(floors+3)
        sigma_f = sqrt(2^(2/floors)-1)*sigma;
        g = gaussian_f(sigma_f);
        sigma = (2^(1/floors))*sigma     %show the value of sigma
        container_sigma(i, j) = sigma*subsample(i);
        filter_size(i, j)= length(g);
        filter_sigma(i,j)=sigma;
        Gaussian_p{i,j} = conv2(Gaussian_p{i, j-1}, g_f, 'same');
        DOG_p{i}(:,:,j-1) = Gaussian_p{i, j} - Gaussian_p{i, j-1};
    end
    if i < levels
        tmp = size(Gaussian_p{i, floors+1});
        [X, Y] = meshgrid(1:2:tmp(2), 1:2:tmp(1));
        Gaussian_p{i+1, 1} = interp2(Gaussian_p{i, floors+1}, X, Y, '*nearest');
        container_sigma(i+1, 1) = container_sigma(i, floors+1);
        subsample = [subsample subsample(end)*2];
    end
end
pyr_time = toc;
fprintf( 2, 'Calcualte the computing time %.2f seconds.\n', pyr_time );

tmp = zeros(1,2);
tmp(2) = (floors+3)*size(Gaussian_p{1,1},2);
for i=1:levels
    tmp(1) = tmp(1)+size(Gaussian_p{i, 1}, 1);
end
pic = zeros(tmp);
y = 1;
for i=1:levels
    x = 1;
    tmp = size(Gaussian_p{i,1});
    for j=1:(floors+3)
        pic(y:(y+tmp(1)-1), x:(x+tmp(2)-1)) = Gaussian_p{i, j};
        x = x + tmp(2);
    end
    y = y + tmp(1);
end
figure('Name', 'Gaussian_p');
imshow(pic);

tmp = zeros(1,2);
tmp(2) = (floors+2)*size(DOG_p{1}(:,:,1),2);
for i = 1:levels
    tmp(1) = tmp(1) + size(DOG_p{i}(:,:,1),1);
end
pic = zeros(tmp);
y = 1;
for i = 1:levels
    x = 1;
    tmp = size(DOG_p{i}(:,:,1));
    for j = 1:(floors + 2)
        pic(y:(y+tmp(1)-1),x:(x+tmp(2)-1)) = 255*DOG_p{i}(:,:,j);
        x = x + tmp(2);
    end
    y = y + tmp(1);
end
figure('Name', 'DOG_p');
imshow(pic);