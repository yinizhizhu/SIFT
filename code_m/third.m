% 下一步是计算特征点的主方向.  
% 在特征点的一个区域内计算其梯度直方图  
g = gaussian_f( 1.5 * absolute_sigma(1,intervals+3) / subsample(1) );  
zero_pad = ceil( 5 / 2 );  

% 计算高斯金字塔图像的梯度方向和幅值  
if interactive >= 1  
fprintf( 2, 'Computing gradient magnitude and orientation...\n' );  
end  
tic;  
mag_thresh = zeros(size(Gaussian_p));  
mag_pyr = cell(size(Gaussian_p));  
grad_pyr = cell(size(Gaussian_p));  
for octave = 1:octaves  
for interval = 2:(intervals+1)  
   
% 计算x,y的差分  
diff_x = 0.5*(Gaussian_p{octave,interval}(2:(end-1),3:(end))-Gaussian_p{octave,interval}(2:(end-1),1:(end-2)));  
diff_y = 0.5*(Gaussian_p{octave,interval}(3:(end),2:(end-1))-Gaussian_p{octave,interval}(1:(end-2),2:(end-1)));  
   
   
% 计算梯度幅值  
mag = zeros(size(Gaussian_p{octave,interval}));  
mag(2:(end-1),2:(end-1)) = sqrt( diff_x .^ 2 + diff_y .^ 2 );  
   
   
% 存储高斯金字塔梯度幅值  
mag_pyr{octave,interval} = zeros(size(mag)+2*zero_pad);  
mag_pyr{octave,interval}((zero_pad+1):(end-zero_pad),(zero_pad+1):(end-zero_pad)) = mag;  
   
   
% 计算梯度主方向  
grad = zeros(size(Gaussian_p{octave,interval}));  
grad(2:(end-1),2:(end-1)) = atan2( diff_y, diff_x );  
grad(find(grad == pi)) = -pi;  
   
   
% 存储高斯金字塔梯度主方向  
grad_pyr{octave,interval} = zeros(size(grad)+2*zero_pad);  
grad_pyr{octave,interval}((zero_pad+1):(end-zero_pad),(zero_pad+1):(end-zero_pad)) = grad;  
end  
end  
clear mag grad  
grad_time = toc;  
if interactive >= 1  
fprintf( 2, 'Gradient calculation time %.2f seconds.\n', grad_time );  
end  
   
   
   
   
   
   
   
   
% 下一步是确定特征点的主方向  
% 方法：通过寻找每个关键点的子区域内梯度直方图的峰值（注：每个关键点的主方向可以有不止一个）  
   
% g = gaussian_f( 1.5 * absolute_sigma(1,intervals+3) / subsample(1) );  
% zero_pad = ceil( length(g) / 2 );  
% 将灰度直方图分为36等分，每隔10度一份  
num_bins = 36;  
hist_step = 2*pi/num_bins;  
hist_orient = [-pi:hist_step:(pi-hist_step)];  
   
   
% 初始化关键点的位置、方向和尺度信息  
pos = [];  
orient = [];  
scale = [];  
   
   
% 给关键点确定主方向  
if interactive >= 1  
fprintf( 2, 'Assigining keypoint orientations...\n' );  
end  
tic;  
for octave = 1:octaves  
if interactive >= 1  
fprintf( 2, '\tProcessing octave %d\n', octave );  
end  
for interval = 2:(intervals + 1)  
if interactive >= 1  
fprintf( 2, '\t\tProcessing interval %d ', interval );  
end  
keypoint_count = 0;  
   
   
% 构造高斯加权掩模  
g = gaussian_f( 1.5 * absolute_sigma(octave,interval)/subsample(octave) );  
hf_sz = floor(5/2);  
   
   
loc_pad = zeros(size(loc{octave,interval})+2*zero_pad);  
loc_pad((zero_pad+1):(end-zero_pad),(zero_pad+1):(end-zero_pad)) = loc{octave,interval};  
   
   
[iy ix]=find(loc_pad==1);  
for k = 1:length(iy)  
   
x = ix(k);  
y = iy(k);  
% % 对其值进行高斯平滑  
wght = g.*mag_pyr{octave,interval}((y-hf_sz):(y+hf_sz),(x-hf_sz):(x+hf_sz));  
grad_window = grad_pyr{octave,interval}((y-hf_sz):(y+hf_sz),(x-hf_sz):(x+hf_sz));  
orient_hist=zeros(length(hist_orient),1);  
for bin=1:length(hist_orient)  
   
diff = mod( grad_window - hist_orient(bin) + pi, 2*pi ) - pi;  
   
   
orient_hist(bin)=orient_hist(bin)+sum(sum(wght.*max(1 - abs(diff)/hist_step,0)));  
   
end  
   
   
% 运用非极大抑制法查找主方向直方图的峰值  
peaks = orient_hist;  
% rot_right = [ peaks(end); peaks(1:end-1) ];  
% rot_left = [ peaks(2:end); peaks(1) ];  
% peaks( find(peaks < rot_right) ) = 0;  
% peaks( find(peaks < rot_left) ) = 0;  
   
   
% 提取最大峰值的值和其索引位置  
[max_peak_val ipeak] = max(peaks);  
   
   
% 将大于等于最大峰值80% 的直方图的也确定为特征点的主方向  
peak_val = max_peak_val;  
while( peak_val > 0.8*max_peak_val )  
       
% 最高峰值最近的三个柱值通过抛物线插值精确得到  
A = [];  
b = [];  
for j = -1:1  
A = [A; (hist_orient(ipeak)+hist_step*j).^2 (hist_orient(ipeak)+hist_step*j) 1];  
     bin = mod( ipeak + j + num_bins - 1, num_bins ) + 1;  
b = [b; orient_hist(bin)];  
end  
c = pinv(A)*b;  
max_orient = -c(2)/(2*c(1));  
while( max_orient < -pi )  
max_orient = max_orient + 2*pi;  
end  
while( max_orient >= pi )  
max_orient = max_orient - 2*pi;  
end  
   
   
% 存储关键点的位置、主方向和尺度信息  
pos = [pos; [(x-zero_pad) (y-zero_pad)]*subsample(octave) ];  
orient = [orient; max_orient];  
scale = [scale; octave interval absolute_sigma(octave,interval)];  
keypoint_count = keypoint_count + 1;  
   
   
% % % 峰值赋0，考察的是下一个峰值，即大于主峰值80%的统计图  
peaks(ipeak) = 0;  
[peak_val ipeak] = max(peaks);  
end  
end  
if interactive >= 1  
fprintf( 2, '(%d keypoints)\n', keypoint_count );  
end  
end  
end  
clear loc loc_pad  
orient_time = toc;  
if interactive >= 1  
fprintf( 2, 'Orientation assignment time %.2f seconds.\n', orient_time );  
end  
   
   
% 在交互模式下显示关键点的尺度和主方向信息  
if interactive >= 2  
fig = figure;  
clf;  
imshow(im);  
hold on;  
display_keypoints( pos, scale(:,3), orient, 'y' );  
% resizeImageFig( fig, size(im), 2 );  
fprintf( 2, 'Final keypoints with scale and orientation (2x scale).\nPress any key to continue.\n' );  
pause;  
close(fig);  
end  