function [cylindricalPos] = convCartesianToCylindrical(cartesianPos)
rVec = sqrt(sum(cartesianPos.^2,2));
cylindricalPos = [rVec,zeros(size(rVec)),zeros(size(rVec))];
end