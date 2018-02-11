function [] = syntheticApertureSim()
close all;
clearvars;
clc;

simLength  = 5;
filtLength = 2;

xVec    = sym('x',[1 simLength]);
yVec    = sym('y',[simLength 1]);
yMEM    = sym('yMEM',[1 filtLength]);
coefVec = sym('a',[1 filtLength]);

yMEM(:) = 0;

for clkId=1:simLength-1
    yVec(clkId) = simplify(simplifyFraction(xVec(clkId) + sum(coefVec(:).*yMEM(:)),'Expand',true));
    yMEM(2:end) = yMEM(1:end-1);
    yMEM(1)     = yVec(clkId);
end

yVec(1:end-1)
yDelay = subs(yVec(1:end-1),xVec(1:end),[0 xVec(1:end-1)])

end