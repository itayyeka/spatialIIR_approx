function [cylindricalPos] = convCartesianToCylindrical(cartesianPos)
cylindricalPos = [sqrt(sum(cartesianPos.^2)),0,0];
end