function [sphericalPos] = convCartesianToSpherical(cartesianPos,funcCfgIn)
try 
    referencePoint = repmat(reshape(funcCfgIn.referencePoint,1,[]),size(cartesianPos,1),1);
catch
    referencePoint = zeros(size(cartesianPos));
end

pointerVec      = cartesianPos - referencePoint;
r               = sqrt(sum(pointerVec.^2,2));                     %sqrt(x^2+y^2+z^2)
phi             = asin(pointerVec(:,3)./r(:));                 %arcsin(z/r)
theta           = acos(pointerVec(:,1)./(r(:).*cos(phi)));  %acos(x/(r*cos(phi)))

try
    funcCfgIn.exportOnlyRadius;
catch
    funcCfgIn.exportOnlyRadius = 0;
end

if funcCfgIn.exportOnlyRadius
    sphericalPos    = r;
else
    sphericalPos    = [r,theta,phi];
end

end