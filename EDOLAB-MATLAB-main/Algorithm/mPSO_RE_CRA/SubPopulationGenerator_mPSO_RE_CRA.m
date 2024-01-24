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
function [Optimizer,Problem] = SubPopulationGenerator_mPSO_RE_CRA(Dimension,MinCoordinate,MaxCoordinate,PopulationSize,Problem)
Optimizer.Archive = [];%初始化子种群的历代最佳位置值档案
Optimizer.Age = 0;
Optimizer.Active = 0;
Optimizer.Robustness = 0;
Optimizer.Gbest_past_environment = NaN(1,Dimension);
Optimizer.Velocity = zeros(PopulationSize,Dimension);
Optimizer.Shifts = [];
Optimizer.SpatialSize = 0;
Optimizer.ShiftSeverity = 1;
Optimizer.X = MinCoordinate + ((MaxCoordinate-MinCoordinate).*rand(PopulationSize,Dimension));
[Optimizer.FitnessValue,Problem] = fitness(Optimizer.X,Problem);
Optimizer.PbestPosition = Optimizer.X;
if Problem.RecentChange == 0
    Optimizer.PbestValue = Optimizer.FitnessValue;
    [Optimizer.BestValue,GbestID] = max(Optimizer.PbestValue);
    Optimizer.BestPosition = Optimizer.PbestPosition(GbestID,:);
else
    Optimizer.FitnessValue = -inf(PopulationSize,1);
    Optimizer.PbestValue = Optimizer.FitnessValue;
    [Optimizer.BestValue,GbestID] = max(Optimizer.PbestValue);
    Optimizer.BestPosition = Optimizer.PbestPosition(GbestID,:);
end