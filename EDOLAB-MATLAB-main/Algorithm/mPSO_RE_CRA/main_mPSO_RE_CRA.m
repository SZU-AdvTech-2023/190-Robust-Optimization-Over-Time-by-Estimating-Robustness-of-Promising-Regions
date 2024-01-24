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
function [Problem,E_bbc,E_o,E_ast,CurrentError,VisualizationInfo,Iteration] = main_mPSO_RE_CRA(VisualizationOverOptimization,PeakNumber,ChangeFrequency,Dimension,ShiftSeverity,EnvironmentNumber,RunNumber,BenchmarkName)
%在这添加ROOT的评价指标
AverageSurvivalTime = NaN(1,RunNumber);
BestErrorBeforeChange = NaN(1,RunNumber);
OfflineError = NaN(1,RunNumber);
CurrentError = NaN (RunNumber,ChangeFrequency*EnvironmentNumber);
for RunCounter=1 : RunNumber
    if VisualizationOverOptimization ~= 1
        rng(RunCounter);%This random seed setting is used to initialize the Problem
    end
    Problem = BenchmarkGenerator(PeakNumber,ChangeFrequency,Dimension,ShiftSeverity,EnvironmentNumber,BenchmarkName);
    rng('shuffle');%Set a random seed for the optimizer
    %% Initialiing Optimizer
    clear Optimizer;
    Optimizer.Dimension = Problem.Dimension;
    Optimizer.PopulationSize = 5;
    Optimizer.MaxCoordinate   = Problem.MaxCoordinate;
    Optimizer.MinCoordinate = Problem.MinCoordinate;
    Optimizer.FreeSwarmID = 1;%Index of the free swarm
    Optimizer.ExclusionLimit = 0.5 * ((Optimizer.MaxCoordinate-Optimizer.MinCoordinate) / ((10) ^ (1 / Optimizer.Dimension)));%这里的10，复现时要改为种群数量
    Optimizer.ConvergenceLimit = Optimizer.ExclusionLimit;
    Optimizer.CoverLimit = 5;%ROOT
    Optimizer.SleepLimit = 0.75;%ROOT
    Optimizer.QuickRecoveryFlag = 0;%ROOT
    Optimizer.DeployFlag = 1;%ROOT
    Optimizer.DiversityPlus = 1;
    Optimizer.x = 0.729843788;
    Optimizer.c1 = 2.05;
    Optimizer.c2 = 2.05;
    Optimizer.SwarmNumber = 1;
    Optimizer.MaxArchive = 9;
    [Optimizer.pop,Problem] = SubPopulationGenerator_mPSO_RE_CRA(Optimizer.Dimension,Optimizer.MinCoordinate,Optimizer.MaxCoordinate,Optimizer.PopulationSize,Problem);
    Optimizer.DeploySolution = Optimizer.pop.BestPosition;%初始化每个环境中部署的解
    Optimizer.DeployValue = Optimizer.pop.BestValue;%部署解的适应度
    Optimizer.SurvivalTime = 0;
    VisualizationFlag=0;
    Iteration=0;
    if VisualizationOverOptimization==1
        VisualizationInfo = cell(1,Problem.MaxEvals);
    else
        VisualizationInfo = [];
    end
    %% main loop
    while 1
        Iteration = Iteration + 1;
        %% Visualization for education module
        if (VisualizationOverOptimization==1 && Dimension == 2)
            if VisualizationFlag==0
                VisualizationFlag=1;
                T = Problem.MinCoordinate : ( Problem.MaxCoordinate-Problem.MinCoordinate)/100 :  Problem.MaxCoordinate;
                L=length(T);
                F=zeros(L);
                for i=1:L
                    for j=1:L
                        F(i,j) = EnvironmentVisualization([T(i), T(j)],Problem);
                    end
                end
            end
            VisualizationInfo{Iteration}.T=T;
            VisualizationInfo{Iteration}.F=F;
            VisualizationInfo{Iteration}.Problem.PeakVisibility = Problem.PeakVisibility(Problem.Environmentcounter , :);
            VisualizationInfo{Iteration}.Problem.OptimumID = Problem.OptimumID(Problem.Environmentcounter);
            VisualizationInfo{Iteration}.Problem.PeaksPosition = Problem.PeaksPosition(:,:,Problem.Environmentcounter);
            VisualizationInfo{Iteration}.CurrentEnvironment = Problem.Environmentcounter;
            counter = 0;           
            for ii=1 : Optimizer.SwarmNumber
                for jj=1 : Optimizer.PopulationSize
                    counter = counter + 1;
                    VisualizationInfo{Iteration}.Individuals(counter,:) = Optimizer.pop(ii).X(jj,:);
                end
            end
            VisualizationInfo{Iteration}.IndividualNumber = counter;
            VisualizationInfo{Iteration}.FE = Problem.FE;
        end
        %% Optimization  
        [Optimizer,Problem] = IterativeComponents_mPSO_RE_CRA(Optimizer,Problem);
        if Problem.RecentChange == 1%When an environmental change has happened
            Problem.RecentChange = 0;
            [Optimizer,Problem] = CalculateRobustness(Optimizer,Problem);
            [Optimizer,Problem] = ChangeReaction_mPSO_RE_CRA(Optimizer,Problem);
            [Optimizer.DeployValue,Problem] = fitness_GMPB(Optimizer.DeploySolution,Problem);
            if Optimizer.DeployValue < Problem.QualityThreshold
                Optimizer.QuickRecoveryFlag = 1;
                Optimizer.DeployFlag = 0;
                Problem.DeadLine = 0;
                Optimizer.SurvivalTime = 0;
                Problem.AverageSurvivalTime = [Problem.AverageSurvivalTime,0];
            else
                Optimizer.SurvivalTime = Optimizer.SurvivalTime + 1;
                Problem.AverageSurvivalTime(end) = Problem.AverageSurvivalTime(end) + Optimizer.SurvivalTime;
            end
            VisualizationFlag = 0;
            clc; disp(['Run number: ',num2str(RunCounter),'   Environment number: ',num2str(Problem.Environmentcounter)]);
        end
        if  Problem.FE >= Problem.MaxEvals%When termination criteria has been met
            break;
        end
    end
    %% Performance indicator calculation
    BestErrorBeforeChange(1,RunCounter) = mean(Problem.Ebbc);
    OfflineError(1,RunCounter) = mean(Problem.CurrentError);
    CurrentError(RunCounter,:) = Problem.CurrentError;
    AverageSurvivalTime(1,RunCounter) = sum(Problem.AverageSurvivalTime)/Problem.Environmentcounter;
end
%% Output preparation
E_bbc.mean = mean(BestErrorBeforeChange);
E_bbc.median = median(BestErrorBeforeChange);
E_bbc.StdErr = std(BestErrorBeforeChange)/sqrt(RunNumber);
E_bbc.AllResults = BestErrorBeforeChange;
E_o.mean = mean(OfflineError);
E_o.median = median(OfflineError);
E_o.StdErr = std(OfflineError)/sqrt(RunNumber);
E_o.AllResults =OfflineError;
E_ast.mean = mean(AverageSurvivalTime);
E_ast.median = median(AverageSurvivalTime);
E_ast.StdErr = std(AverageSurvivalTime)/sqrt(RunNumber);
E_ast.AllResults = AverageSurvivalTime;
if VisualizationOverOptimization==1
    tmp = cell(1, Iteration);
    for ii=1 : Iteration
        tmp{ii} = VisualizationInfo{ii};
    end
    VisualizationInfo = tmp;
end