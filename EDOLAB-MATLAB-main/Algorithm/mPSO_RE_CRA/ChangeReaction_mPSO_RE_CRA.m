%********************************mPSO*****************************************************
%Author: Delaram Yazdani
%E-mail: delaram DOT yazdani AT yahoo DOT com
%Last Edited: October 4, 2021
%
% ------------
% Reference:
% ------------
%
%  Danial Yazdani et al.,
%            "Scaling Up Dynamic Optimization Problems: A Divide-and-Conquer Approach"
%            IEEE Transaction on Evolutionary Computation, 2019.
%
% --------
% License:
% --------
% This program is to be used under the terms of the GNU General Public License
% (http://www.gnu.org/copyleft/gpl.html).
% E-mail: danial DOT yazdani AT gmail DOT com
% Copyright notice: (c) 2023 Danial Yazdani
%*****************************************************************************************
function [Optimizer,Problem] = ChangeReaction_mPSO_RE_CRA(Optimizer,Problem)
%% Updating Shift Severity and Introducing diversity (all except free swarm)(改为对所有spatial size小于Rconv的子种群引入多样性)
for jj=1 : Optimizer.SwarmNumber
    if Optimizer.pop(jj).SpatialSize < Optimizer.ConvergenceLimit
        if sum(isnan(Optimizer.pop(jj).Gbest_past_environment))==0
            Optimizer.pop(jj).Shifts = [Optimizer.pop(jj).Shifts , pdist2(Optimizer.pop(jj).Gbest_past_environment,Optimizer.pop(jj).BestPosition)];
            Optimizer.pop(jj).ShiftSeverity = mean(Optimizer.pop(jj).Shifts);
        end
        Optimizer.pop(jj).X = repmat(Optimizer.pop(jj).BestPosition,Optimizer.PopulationSize,1)+ (rands(Optimizer.PopulationSize,Optimizer.Dimension)*Optimizer.pop(jj).ShiftSeverity);
        Optimizer.pop(jj).X(1,:) = Optimizer.pop(jj).BestPosition;
    end
end
%% Updating memory
for jj=1 : Optimizer.SwarmNumber
    [Optimizer.pop(jj).FitnessValue,Problem] = fitness(Optimizer.pop(jj).X , Problem);
    Optimizer.pop(jj).PbestValue = Optimizer.pop(jj).FitnessValue;
    Optimizer.pop(jj).PbestPosition = Optimizer.pop(jj).X;
    Optimizer.pop(jj).Gbest_past_environment = Optimizer.pop(jj).BestPosition;
    [Optimizer.pop(jj).BestValue,BestPbestID] = max(Optimizer.pop(jj).PbestValue);
    Optimizer.pop(jj).BestPosition = Optimizer.pop(jj).PbestPosition(BestPbestID,:);
end