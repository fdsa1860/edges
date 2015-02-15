function [E,O,inds,segs] = edgesDetect( I, model )
% Detect edges in image.
%
% For an introductory tutorial please see edgesDemo.m.
%
% The following model params may be altered prior to detecting edges:
%  prm = stride, sharpen, multiscale, nTreesEval, nThreads, nms
% Simply alter model.opts.prm. For example, set model.opts.nms=1 to enable
% non-maximum suppression. See edgesTrain for parameter details.
%
% USAGE
%  [E,O,inds,segs] = edgesDetect( I, model )
%
% INPUTS
%  I          - [h x w x 3] color input image
%  model      - structured edge model trained with edgesTrain
%
% OUTPUTS
%  E          - [h x w] edge probability map
%  O          - [h x w] coarse edge normal orientation (0=left, pi/2=up)
%  inds       - [h/s x w/s x nTreesEval] leaf node indices
%  segs       - [g x g x h/s x w/s x nTreesEval] local segmentations
%
% EXAMPLE
%
% See also edgesDemo, edgesTrain, edgesChns
%
% Structured Edge Detection Toolbox      Version 3.01
% Code written by Piotr Dollar, 2014.
% Licensed under the MSR-LA Full Rights License [see license.txt]

% get parameters
opts=model.opts; opts.nTreesEval=min(opts.nTreesEval,opts.nTrees);
if(~isfield(opts,'sharpen')), opts.sharpen=0; end
if(~isfield(model,'segs')), model.segs=[]; model.nSegs=[]; end
opts.stride=max(opts.stride,opts.shrink); model.opts=opts;

if( opts.multiscale )
  % if multiscale run edgesDetect multiple times
  ss=2.^(-1:1); k=length(ss); inds=cell(1,k); segs=inds;
  siz=size(I); model.opts.multiscale=0; model.opts.nms=0; E=0;
  for i=1:k, s=ss(i); I1=imResample(I,s);
    if(nargout<4), [E1,~,inds{i}]=edgesDetect(I1,model);
    else [E1,~,inds{i},segs{i}]=edgesDetect(I1,model); end
    E=E+imResample(E1,siz(1:2));
  end; E=E/k; model.opts=opts;
  
else
    % scale I
    scale = 2;
    I = imresize(I,scale,'bilinear');
  % pad image, making divisible by 4
  siz=size(I); r=opts.imWidth/2; p=[r r r r];
  p([2 4])=p([2 4])+mod(4-mod(siz(1:2)+2*r,4),4);
  I = imPad(I,p,'symmetric');
  
  % compute features and apply forest to image
  [chnsReg,chnsSim] = edgesChns( I, opts );
  s=opts.sharpen; if(s), I=convTri(rgbConvert(I,'rgb'),1); end
%   if(nargout<4), [E,inds] = edgesDetectMex(model,I,chnsReg,chnsSim);
%   else [E,inds,segs] = edgesDetectMex(model,I,chnsReg,chnsSim); end
  if(nargout<4), [E,inds] = dymEdgesDetectMex(model,I,chnsReg,chnsSim);
  else [E,inds,segs] = dymEdgesDetectMex(model,I,chnsReg,chnsSim); end
%   E(E<5)=0;
  E(E<4)=0;
  
  % normalize and finalize edge maps
  t=opts.stride^2/opts.gtWidth^2/opts.nTreesEval; r=opts.gtWidth/2;
  if(s==0), t=t*2; elseif(s==1), t=t*1.8; else t=t*1.66; end
  E=E(1+r:siz(1)+r,1+r:siz(2)+r,:)*t; E=convTri(E,1);
end

% % compute approximate orientation O from edges E
% if( opts.nms==-1 ), O=[]; elseif( nargout>1 || opts.nms )
%   [Ox,Oy]=gradient2(convTri(E,4));
%   [Oxx,~]=gradient2(Ox); [Oxy,Oyy]=gradient2(Oy);
%   O=mod(atan(Oyy.*sign(-Oxy)./(Oxx+1e-5)),pi);
% end
% % perform nms
% if( opts.nms>0 ), E=edgesNmsMex(E,O,1,5,1.01,opts.nThreads); end

% nms modified by xikang
[V,E] = max(E,[],3);
% V = sum(E,3); [~,E] = max(E,[],3);
if( opts.nms==-1 ), O=[]; elseif( nargout>1 || opts.nms )
  [Ox,Oy]=gradient2(convTri(V,4));
  [Oxx,~]=gradient2(Ox); [Oxy,Oyy]=gradient2(Oy);
  O=mod(atan(Oyy.*sign(-Oxy)./(Oxx+1e-5)),pi);
end
if( opts.nms>0 ), V=edgesNmsMex(V,O,1,5,1.01,opts.nThreads); end

% color image
E(V<1e-2)=0;
[m,n] = find(E~=0);
color = hsv(10);
E3 = zeros([size(E,1) size(E,2) 3]);
for i = 1:length(m)
    E3(m(i),n(i),:) = color(E(m(i),n(i)),:);
end
E = E3;

% scale back
% E = imresize(E,1/scale,'bilinear');

% E = V/max(V(:)); % gray image

end
