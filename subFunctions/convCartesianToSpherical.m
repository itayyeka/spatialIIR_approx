function [SphericalPos] = convCartesianToSpherical(cartesianPos)
rVec = sqrt(sum(cartesianPos.^2,2));
SphericalPos = [rVec,zeros(size(rVec)),zeros(size(rVec))];
end