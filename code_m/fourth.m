% SIFT �㷨�����һ����������������  
  
  
orient_bin_spacing = pi/4;  
orient_angles = [-pi:orient_bin_spacing:(pi-orient_bin_spacing)];  
  
  
grid_spacing = 4;  
[x_coords y_coords] = meshgrid( [-6:grid_spacing:6] );  
feat_grid = [x_coords(:) y_coords(:)]';  
[x_coords y_coords] = meshgrid( [-(2*grid_spacing-0.5):(2*grid_spacing-0.5)] );  
feat_samples = [x_coords(:) y_coords(:)]';  
feat_window = 2*grid_spacing;  
  
  
desc = [];  
  
  
if interactive >= 1  
   fprintf( 2, 'Computing keypoint feature descriptors for %d keypoints', size(pos,1) );  
end  
for k = 1:size(pos,1)  
   x = pos(k,1)/subsample(scale(k,1));  
   y = pos(k,2)/subsample(scale(k,1));     
     
  
   % ����������תΪ�ؼ���ķ�����ȷ����ת������  
   M = [cos(orient(k)) -sin(orient(k)); sin(orient(k)) cos(orient(k))];  
   feat_rot_grid = M*feat_grid + repmat([x; y],1,size(feat_grid,2));  
   feat_rot_samples = M*feat_samples + repmat([x; y],1,size(feat_samples,2));  
     
  
   % ��ʼ����������.  
   feat_desc = zeros(1,128);  
     
  
   for s = 1:size(feat_rot_samples,2)  
      x_sample = feat_rot_samples(1,s);  
      y_sample = feat_rot_samples(2,s);  
        
  
      % �ڲ���λ�ý����ݶȲ�ֵ  
      [X Y] = meshgrid( (x_sample-1):(x_sample+1), (y_sample-1):(y_sample+1) );  
      G = interp2( gauss_pyr{scale(k,1),scale(k,2)}, X, Y, '*linear' );  
      G(find(isnan(G))) = 0;  
      diff_x = 0.5*(G(2,3) - G(2,1));  
      diff_y = 0.5*(G(3,2) - G(1,2));  
      mag_sample = sqrt( diff_x^2 + diff_y^2 );  
      grad_sample = atan2( diff_y, diff_x );  
      if grad_sample == pi  
         grad_sample = -pi;  
      end        
        
  
      % ����x��y�����ϵ�Ȩ��  
      x_wght = max(1 - (abs(feat_rot_grid(1,:) - x_sample)/grid_spacing), 0);  
      y_wght = max(1 - (abs(feat_rot_grid(2,:) - y_sample)/grid_spacing), 0);   
      pos_wght = reshape(repmat(x_wght.*y_wght,8,1),1,128);  
        
  
      diff = mod( grad_sample - orient(k) - orient_angles + pi, 2*pi ) - pi;  
      orient_wght = max(1 - abs(diff)/orient_bin_spacing,0);  
      orient_wght = repmat(orient_wght,1,16);           
        
  
      % �����˹Ȩ��  
      g = exp(-((x_sample-x)^2+(y_sample-y)^2)/(2*feat_window^2))/(2*pi*feat_window^2);  
        
  
      feat_desc = feat_desc + pos_wght.*orient_wght*g*mag_sample;  
   end  
     
  
   % �����������ĳ��ȹ�һ��������Խ�һ��ȥ�����ձ仯��Ӱ��.  
   feat_desc = feat_desc / norm(feat_desc);  
     
  
   feat_desc( find(feat_desc > 0.2) ) = 0.2;  
   feat_desc = feat_desc / norm(feat_desc);  
     
  
   % �洢��������.  
   desc = [desc; feat_desc];  
   if (interactive >= 1) & (mod(k,25) == 0)  
      fprintf( 2, '.' );  
   end  
end  
desc_time = toc;  
  
  
% ��������ƫ��  
sample_offset = -(subsample - 1);  
for k = 1:size(pos,1)  
   pos(k,:) = pos(k,:) + sample_offset(scale(k,1));  
end  
  
  
if size(pos,1) > 0  
    scale = scale(:,3);  
end  
     
  
% �ڽ���ģʽ����ʾ���й��̺�ʱ.  
if interactive >= 1  
   fprintf( 2, '\nDescriptor processing time %.2f seconds.\n', desc_time );  
   fprintf( 2, 'Processing time summary:\n' );  
   fprintf( 2, '\tPreprocessing:\t%.2f s\n', pre_time );  
   fprintf( 2, '\tPyramid:\t%.2f s\n', pyr_time );  
   fprintf( 2, '\tKeypoints:\t%.2f s\n', keypoint_time );  
   fprintf( 2, '\tGradient:\t%.2f s\n', grad_time );  
   fprintf( 2, '\tOrientation:\t%.2f s\n', orient_time );  
   fprintf( 2, '\tDescriptor:\t%.2f s\n', desc_time );  
   fprintf( 2, 'Total processing time %.2f seconds.\n', pre_time + pyr_time + keypoint_time + grad_time + orient_time + desc_time );  
end  