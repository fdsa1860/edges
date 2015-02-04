function E = dymEdgeDraw(E)

% [V,E] = max(E,[],3);
% E(V<1e-4)=0;
[m,n] = find(E~=0);
color = hsv(10);
E3 = zeros([size(E,1) size(E,2) 3]);
for i = 1:length(m)
    E3(m(i),n(i),:) = color(E(m(i),n(i)),:);
end
E = E3;

end