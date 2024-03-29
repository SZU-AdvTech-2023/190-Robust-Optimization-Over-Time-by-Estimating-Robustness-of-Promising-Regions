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
function [Optimizer , Problem] = IterativeComponents_mPSO_RE_CRA(Optimizer,Problem)
%%Computational resource allocation
[Optimizer,Problem] = CRA(Optimizer,Problem);
TmpSwarmNum = Optimizer.SwarmNumber;
%%Sub-swarm movement
for ii=1 : Optimizer.SwarmNumber
    if Optimizer.pop(ii).Active==1
        if and(Optimizer.DeployFlag == 0 , Problem.DeadLine + size(Optimizer.pop(ii).X,1) > Problem.ComputationalBudget)
            %选一个解部署
            Optimizer.QuickRecoveryFlag = 0;
            [Optimizer,Problem] = SelectDeploySolution(Optimizer,Problem);
        end
        Optimizer.pop(ii).Velocity = Optimizer.x * ...
            (Optimizer.pop(ii).Velocity + (Optimizer.c1 * rand(Optimizer.PopulationSize , Optimizer.Dimension).*(Optimizer.pop(ii).PbestPosition - Optimizer.pop(ii).X)) + ...
            (Optimizer.c2*rand(Optimizer.PopulationSize , Optimizer.Dimension).*(repmat(Optimizer.pop(ii).BestPosition,Optimizer.PopulationSize,1) - Optimizer.pop(ii).X)));
        Optimizer.pop(ii).X = Optimizer.pop(ii).X + Optimizer.pop(ii).Velocity;

        for jj=1 : Optimizer.PopulationSize
            for kk=1 : Optimizer.Dimension
                if Optimizer.pop(ii).X(jj,kk) > Optimizer.MaxCoordinate
                    Optimizer.pop(ii).X(jj,kk) = Optimizer.MaxCoordinate;
                    Optimizer.pop(ii).Velocity(jj,kk) = 0;
                elseif Optimizer.pop(ii).X(jj,kk) < Optimizer.MinCoordinate
                    Optimizer.pop(ii).X(jj,kk) = Optimizer.MinCoordinate;
                    Optimizer.pop(ii).Velocity(jj,kk) = 0;
                end
            end
        end

        [tmp,Problem] = fitness(Optimizer.pop(ii).X,Problem);
        if Optimizer.DeployFlag == 0%当前环境尚未部署解，则需要计算DDl
            Problem.DeadLine = Problem.DeadLine + size(tmp,1);
        end
        if Problem.RecentChange == 1
            return;
        end
        Optimizer.pop(ii).FitnessValue = tmp;
        for jj=1 : Optimizer.PopulationSize
            if Optimizer.pop(ii).FitnessValue(jj) > Optimizer.pop(ii).PbestValue(jj)
                Optimizer.pop(ii).PbestValue(jj) = Optimizer.pop(ii).FitnessValue(jj);
                Optimizer.pop(ii).PbestPosition(jj,:) = Optimizer.pop(ii).X(jj,:);
            end
        end
        [BestPbestValue,BestPbestID] = max(Optimizer.pop(ii).PbestValue);
        if BestPbestValue>Optimizer.pop(ii).BestValue
            Optimizer.pop(ii).BestValue = BestPbestValue;
            Optimizer.pop(ii).BestPosition = Optimizer.pop(ii).PbestPosition(BestPbestID,:);
        end
     end
end
%% Exclusion
ExclusionFlag = 0;
for ii=1 : Optimizer.SwarmNumber
    for jj=1 : Optimizer.SwarmNumber
        if ii~=jj && ExclusionFlag==0 && pdist2(Optimizer.pop(ii).BestPosition,Optimizer.pop(jj).BestPosition)<Optimizer.ExclusionLimit
            if Optimizer.pop(ii).BestValue<Optimizer.pop(jj).BestValue
                if Optimizer.FreeSwarmID~=ii
                    Optimizer.pop(ii) = [];
                    Optimizer.SwarmNumber = Optimizer.SwarmNumber-1;
                    Optimizer.FreeSwarmID = Optimizer.FreeSwarmID-1;
                else
                    [Optimizer.pop(ii),Problem] = SubPopulationGenerator_mPSO_RE_CRA(Optimizer.Dimension,Optimizer.MinCoordinate,Optimizer.MaxCoordinate,Optimizer.PopulationSize,Problem);
                    if Problem.RecentChange == 1
                        return;
                    end
                end
            else
                if Optimizer.FreeSwarmID~=jj
                    Optimizer.pop(jj) = [];
                    Optimizer.SwarmNumber = Optimizer.SwarmNumber-1;
                    Optimizer.FreeSwarmID = Optimizer.FreeSwarmID-1;
                else
                    [Optimizer.pop(jj),Problem] = SubPopulationGenerator_mPSO_RE_CRA(Optimizer.Dimension,Optimizer.MinCoordinate,Optimizer.MaxCoordinate,Optimizer.PopulationSize,Problem);
                    if Problem.RecentChange == 1
                        return;
                    end
                end
            end
            ExclusionFlag = 1;
        end
    end
end
%% FreeSwarm Convergence
%计算每个子种群的spatial size，并以此判断种群是否收敛
ConvergenceFlag = 1;
for ii=1 : Optimizer.SwarmNumber
    TmpSet = pdist(Optimizer.pop(ii).X);
    Optimizer.pop(ii).SpatialSize = max(TmpSet);
    if Optimizer.pop(ii).SpatialSize > Optimizer.ConvergenceLimit
        ConvergenceFlag = 0;
    end
end
if ConvergenceFlag==1%所有子种群都已收敛，则新建一个子种群
    Optimizer.SwarmNumber = Optimizer.SwarmNumber+1;
    Optimizer.FreeSwarmID = Optimizer.SwarmNumber;
    [Optimizer.pop(Optimizer.FreeSwarmID),Problem] = SubPopulationGenerator_mPSO_RE_CRA(Optimizer.Dimension,Optimizer.MinCoordinate,Optimizer.MaxCoordinate,Optimizer.PopulationSize,Problem);
    if Problem.RecentChange == 1
        return;
    end
end
%% Updating Thresholds
if TmpSwarmNum ~= Optimizer.SwarmNumber
    Optimizer.ExclusionLimit = 0.5 * ((Optimizer.MaxCoordinate-Optimizer.MinCoordinate) / ((Optimizer.SwarmNumber) ^ (1 / Optimizer.Dimension)));
    Optimizer.ConvergenceLimit = Optimizer.ExclusionLimit;
    %     if Optimizer.ExclusionLimit > Optimizer.MinExclusionLimit
%         Optimizer.ExclusionLimit = Optimizer.MinExclusionLimit;
%     end
end
%% Deactivation
for ii = 1:Optimizer.SwarmNumber
    Optimizer.pop(ii).Active = 0;
end
% for kk=1 : Optimizer.SwarmNumber
%     DeactivationFlag = 1;
%     for ii=1 : Optimizer.PopulationSize
%         for jj=1 : Optimizer.PopulationSize
%             if DeactivationFlag==1 && ii~=jj
%                 if pdist2(Optimizer.pop(kk).X(ii,:),Optimizer.pop(kk).X(jj,:))>Optimizer.SleepingLimit
%                     DeactivationFlag = 0;
%                 end
%             end
%         end
%         if DeactivationFlag==1 && kk~=Optimizer.FreeSwarmID
%             Optimizer.pop(kk).Active=0;
%         end
%     end
% end