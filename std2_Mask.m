function [ std ] = std2_Mask( mat, mask, varargin )
%compute standard deviation of matrix, restricted to mask
%varargin{1}: if present and set to true, 0-clipping is taken into account
%by seeting mean to 0 and excluding pixels <=0
mat=double(mat);
mask=double(mask);
weights=sum(sum(mask));
if(nargin==2)
    mean=sum(sum(mat.*mask));
    mean=mean/weights;
elseif(nargin==3)
    if(varargin{1})
        mean=0;
        mask=mask.*(mat>0);
        weights=sum(sum(mask));
    end
else
    error('number of arguments incorrect')
end

std=sum(sum(((mat-mean).^2).*mask));
std=std/weights;
std=sqrt(std);
end

