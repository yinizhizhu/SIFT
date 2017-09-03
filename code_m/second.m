% ��һ���ǲ��Ҳ�ָ�˹�������еľֲ���ֵ����ͨ�����ʺ��նȽ��м���  
interactive = 2;            %%���õ�������  
curvature_threshold = 10.0; %%����ȥ����Ե��������ֵ��С  
contrast_threshold = 0.02;  %%����ȥ���ͶԱȶ���������ֵ��С  
curvature_threshold = ((curvature_threshold + 1)^2)/curvature_threshold;  
 
% ����΢�ֺ�  
xx = [ 1 -2  1 ];  
yy = xx';  
xy = [ 1 0 -1; 0 0 0; -1 0 1 ]/4;  
  
  
raw_keypoints = [];%%ԭʼ������  
contrast_keypoints = [];%%�Աȶ�  
curve_keypoints = [];%%����  

% �ڸ�˹�������в��Ҿֲ���ֵ  
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
                    
               % ͨ���ռ�˳߶ȼ�����ֵ����Сֵ  
                  tmp = DOG_p{level}((y-1):(y+1),(x-1):(x+1),(floor-1):(floor+1)); %%ȡ����λ�õ�����3�㣬��27����   
                  pt_val = tmp(2,2,2);            %%�õ����м�Ĵ�����ڶ���ڶ��ŵڶ���  
                  if( (pt_val == min(tmp(:))) | (pt_val == max(tmp(:))) )  
%                       % �洢��ֵ��                                             
%                      raw_keypoints = [raw_keypoints; x*subsample(level) y*subsample(level)]; %%���Բ�����������ԭ��ԭʼͼƬ������  
   
%%������ֵ  
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
                                          
  
                      % �洢�ԻҶȴ��ڶԱȶ���ֵ�ĵ������  
                     if (abs(contr) >= contrast_threshold)  
                        raw_keypoints = [raw_keypoints; x*subsample(level) y*subsample(level)]; %%���Բ�����������ԭ��ԭʼͼƬ������  
                        contrast_keypoints = [contrast_keypoints; raw_keypoints(end,:)];%%�洢�������һ����ֵ�������¼�⵽��ֵ  
                          
                        % ����ֲ���ֵ��Hessian����  
                        Dxx = sum(DOG_p{level}(y,x-1:x+1,floor) .* xx);  
                        Dyy = sum(DOG_p{level}(y-1:y+1,x,floor) .* yy);  
                        Dxy = sum(sum(DOG_p{level}(y-1:y+1,x-1:x+1,floor) .* xy));  
                          
                        % ����Hessian�����ֱ��������ʽ.  
                        Tr_H = Dxx + Dyy;  
                        Det_H = Dxx*Dyy - Dxy^2;  
                          
  
                        % ����������.  
                        curvature_ratio = (Tr_H^2)/Det_H;  
                          
                        if ((Det_H >= 0) & (curvature_ratio < curvature_threshold))  
  
                           % �洢������С����ֵ�ĵļ�ֵ������꣨�Ǳ�Ե�㣩  
                           curve_keypoints = [curve_keypoints; raw_keypoints(end,:)];  
                           % ���õ��λ�õ�������Ϊ1��������������.  
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

% �ڽ���ģʽ����ʾ��������Ľ��.
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


