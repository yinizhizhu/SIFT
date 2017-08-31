function[g,x] = gaussian_f(sigma, sample)
if ~exist('sample')  
    sample = 7.0/2.0;  
end  
n = 2*round(sample * sigma) + 1;  
x = 1:n;  
x = x-ceil(n/2);
g = zeros(n, n);
for i=1:n
    for j=1:n
        g(i, j) = exp(-(x(i)^2+x(j)^2)/(2*sigma^2))/(2*pi*sigma^2);
    end
end

end