function [Optimizer,Problem] = SelectDeploySolution(Optimizer,Problem)
%SelectDeploySolution 选择部署解
%   环境变化后首先评估上一环境中的部署解是否仍满足要求，若不满足则部署一个新的解
    RobustArray = [Optimizer.pop(:).Robustness];
    MaxRobust = max(RobustArray);
    MaxRobustID = find(RobustArray == MaxRobust);
    BestValue = -inf;
    BestID = 0;
    for ii = MaxRobustID
        if Optimizer.pop(ii).BestValue > BestValue
            BestValue = Optimizer.pop(ii).BestValue;
            BestID = ii;
        end
    end
    Optimizer.DeploySolution = Optimizer.pop(BestID).BestPosition;
    Optimizer.DeployValue = BestValue;
    Optimizer.DeployFlag = 1;
end

