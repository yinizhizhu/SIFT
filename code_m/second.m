% 下一步是查找差分高斯金字塔中的局部极值，并通过曲率和照度进行检验  
interactive = 2;            %%设置迭代次数  
curvature_threshold = 10.0; %%设置去除边缘特征点阈值大小  
contrast_threshold = 0.02;  %%设置去除低对比度特征点阈值大小  
curvature_threshold = ((curvature_threshold + 1)^2)/curvature_threshold;  
 
% 二阶微分核  
xx = [ 1 -2  1 ];  
yy = xx';  
xy = [ 1 0 -1; 0 0 0; -1 0 1 ]/4;  
  
  
raw_keypoints = [];%%原始特征点  
contrast_keypoints = [];%%对比度  
curve_keypoints = [];%%曲率  

% 在高斯金字塔中查找局部极值  
if interactive >= 1  
   fprintf( 2, 'Locating keypoints...\n' );  
end  
tic;  
loc = cell(size(DOG_p));  
for level = 1:levels  
   if interactive >= 1  
      fprintf( 2, '\tProcessing level %d\n', level );  
   end  
   for floor = 2:(floors+1)  
      keypoint_count = 0;  
      contrast_mask = abs(DOG_p{level}(:,:,floor)) >= contrast_threshold;  
      loc{level,floor} = zeros(size(DOG_p{level}(:,:,floor)));  
     edge = ceil(filter_size(level,floor)/2);  
      for y=(1+edge):(size(DOG_p{level}(:,:,floor),1)-edge)  
          y_size = size(DOG_p{level}(:,:,floor),1)-edge;  
         for x=(1+edge):(size(DOG_p{level}(:,:,floor),2)-edge)  
            x_size = size(DOG_p{level}(:,:,floor),2)-edge;  
            if object_mask(round(y*subsample(level)),round(x*subsample(level))) == 1   
                 
                 
               if( (interactive >= 2) | (contrast_mask(y,x) == 1) )   
                    
               % 通过空间核尺度检测最大值和最小值  
                  tmp = DOG_p{level}((y-1):(y+1),(x-1):(x+1),(floor-1):(floor+1)); %%取出该位置的上下3层，共27个点   
                  pt_val = tmp(2,2,2);            %%该点是中间的待检测点第二层第二排第二列  
                  if( (pt_val == min(tmp(:))) | (pt_val == max(tmp(:))) )  
%                       % 存储极值点                                             
%                      raw_keypoints = [raw_keypoints; x*subsample(level) y*subsample(level)]; %%乘以采样的数，还原到原始图片的坐标  
   
%%迭代插值  
                         for i=1:interactive  
                             Ddx = (DOG_p{level}(y,(x+1),floor)-DOG_p{level}(y,(x-1),floor))*0.5;  
                             Ddy = (DOG_p{level}(y+1,x,floor)-DOG_p{level}(y-1,x,floor))*0.5;  
                             Ddsigama = (DOG_p{level}(y,x,floor+1)-DOG_p{level}(y,x,floor-1))*0.5;  
                               
                               
                             v2 = DOG_p{level}(y,x,floor)*2;  
                             dxx = (DOG_p{level}(y,(x+1),floor)-DOG_p{level}(y,(x-1),floor) - v2);  
                             dyy = (DOG_p{level}(y+1,x,floor)-DOG_p{level}(y-1,x,floor) - v2);  
                             dss = (DOG_p{level}(y,x,floor+1)-DOG_p{level}(y,x,floor-1)-v2);  
                               
                               
                             dxy = (DOG_p{level}(y+1,x+1,floor)-DOG_p{level}(y+1,x-1,floor)-DOG_p{level}(y-1,x+1,floor)+DOG_p{level}(y-1,x-1,floor))*0.25;  
                             dxs = (DOG_p{level}(y,x+1,floor+1)-DOG_p{level}(y,x-1,floor+1)-DOG_p{level}(y,x+1,floor-1)+DOG_p{level}(y,x-1,floor-1))*0.25;  
                             dys = (DOG_p{level}(y+1,x,floor+1)-DOG_p{level}(y-1,x,floor+1)-DOG_p{level}(y+1,x,floor-1)+DOG_p{level}(y-1,x,floor-1))*0.25;  
                             HH = [dxx,dxy,dxs;dxy,dyy,dys;dxs,dys,dss];  
                           
                             D = [Ddx,Ddy,Ddsigama];  
                             X = inv(HH)*D';  
                             xi = -X(3);  
                             xr = -X(2);  
                             xc = -X(1);  
                             if (abs(xi)<0.5&abs(xr)<0.5&abs(xc)<0.5)  
                                 break;  
                             end  
                              if (abs(xi)>2147483647|abs(xr)>2147483647|abs(xc)>2147483647)  
                                  i = interactive + 1;  
                                 break;  
                              end  
                             x = x+ round(xc);  
                             y= y + round(xr);  
                             floor = floor + round(xi);  
                             if(floor<1|floor>(floors+1)|x<edge|x>x_size|y<edge|y>y_size)  
                                 i = interactive + 1;  
                             break;  
                             end                               
                             end  
                           
                      if(i<interactive)  
                          Ddx = (DOG_p{level}(y,(x+1),floor)-DOG_p{level}(y,(x-1),floor))*0.5;  
                          Ddy = (DOG_p{level}(y+1,x,floor)-DOG_p{level}(y-1,x,floor))*0.5;  
                          Ddsigama = (DOG_p{level}(y,x,floor+1)-DOG_p{level}(y,x,floor-1))*0.5;  
                          D = [Ddx,Ddy,Ddsigama];  
                          t = (D) * (X) ;  
                          contr = DOG_p{level}(y,x,floor) + 0.5*t;  
                                          
  
                      % 存储对灰度大于对比度阈值的点的坐标  
                     if (abs(contr) >= contrast_threshold)  
                        raw_keypoints = [raw_keypoints; x*subsample(level) y*subsample(level)]; %%乘以采样的数，还原到原始图片的坐标  
                        contrast_keypoints = [contrast_keypoints; raw_keypoints(end,:)];%%存储的是最后一个的值，即最新检测到的值  
                          
                        % 计算局部极值的Hessian矩阵  
                        Dxx = sum(DOG_p{level}(y,x-1:x+1,floor) .* xx);  
                        Dyy = sum(DOG_p{level}(y-1:y+1,x,floor) .* yy);  
                        Dxy = sum(sum(DOG_p{level}(y-1:y+1,x-1:x+1,floor) .* xy));  
                          
                        % 计算Hessian矩阵的直迹和行列式.  
                        Tr_H = Dxx + Dyy;  
                        Det_H = Dxx*Dyy - Dxy^2;  
                          
  
                        % 计算主曲率.  
                        curvature_ratio = (Tr_H^2)/Det_H;  
                          
                        if ((Det_H >= 0) & (curvature_ratio < curvature_threshold))  
  
                           % 存储主曲率小于阈值的的极值点的坐标（非边缘点）  
                           curve_keypoints = [curve_keypoints; raw_keypoints(end,:)];  
                           % 将该点的位置的坐标设为1，并计算点的数量.  
                           loc{level,floor}(y,x) = 1;  
                           keypoint_count = keypoint_count + 1;  
                        end  
                     end  
                     end                    
                  end  
               end                 
            end  
         end           
      end  
      if interactive >= 1  
         fprintf( 2, '\t\t%d keypoints found on floor %d\n', keypoint_count, floor );  
      end  
   end  
end  
keypoint_time = toc;  
if interactive >= 1  
   fprintf( 2, 'Keypoint location time %.2f seconds.\n', keypoint_time );  
end     

% 在交互模式下显示特征点检测的结果.
if interactive >= 2  
   figure('Name', 'First');
   clf;
   imshow(im);
   hold on;  
   plot(raw_keypoints(:,1),raw_keypoints(:,2),'y+');  
   fprintf( 2, 'DOG extrema (2x scale).\nPress any key to continue.\n' );
   figure('Name', 'Second');
   imshow(im);  
   hold on;  
   plot(contrast_keypoints(:,1),contrast_keypoints(:,2),'y+');  
   fprintf( 2, 'Keypoints after removing low contrast extrema (2x scale).\nPress any key to continue.\n' );  
   figure('Name', 'Third');
   imshow(im);  
   hold on;  
   plot(curve_keypoints(:,1),curve_keypoints(:,2),'y+');  
   fprintf( 2, 'Keypoints after removing edge points using principal curvature filtering (2x scale).\nPress any key to continue.\n' );  
end  
clear raw_keypoints contrast_keypoints curve_keypoints  


