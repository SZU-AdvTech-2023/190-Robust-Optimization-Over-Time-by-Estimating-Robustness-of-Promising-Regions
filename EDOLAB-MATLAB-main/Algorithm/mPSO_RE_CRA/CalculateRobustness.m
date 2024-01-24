function [Optimizer,Problem] = CalculateRobustness(Optimizer,Problem)
%CALCULATEROBUSTNESS 计算各种群的鲁棒值
%   通过计算子种群档案中满足质量门槛的连续代数来估计子种群的鲁棒性，同时进行档案管理
for ii = 1 : Optimizer.SwarmNumber
    Optimizer.pop(ii).Age = Optimizer.pop(ii).Age + 1;
    if Optimizer.pop(ii).Age > 1
        Optimizer.pop(ii).Archive = [Optimizer.pop(ii).Archive;Optimizer.pop(ii).BestPosition];
        ArchiveNumber = size(Optimizer.pop(ii).Archive,1);
        jj = ArchiveNumber;
        Robustness = 0;
        while jj > 0 
            [TmpValue,Problem] = fitness_GMPB(Optimizer.pop(ii).Archive(jj,:),Problem);
            if TmpValue >= Problem.QualityThreshold
                Robustness = Robustness + 1;
                jj = jj - 1;
            else
                break;
            end
        end
        if jj > 0
            Optimizer.pop(ii).Archive(1:jj,:) = [];
        end
        Optimizer.pop(ii).Robustness = Robustness;
    end
end
end

