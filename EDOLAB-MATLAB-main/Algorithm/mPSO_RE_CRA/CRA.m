function [Optimizer,Problem] = CRA(Optimizer,Problem)
%CRA Computational Resource Allocation
%   通过当前环境信息选择本次迭代中要优化的子种群
    if Problem.Environmentcounter == 1 
        for ii = 1:Optimizer.SwarmNumber
            if  Optimizer.pop(ii).SpatialSize > Optimizer.SleepLimit
                Optimizer.pop(ii).Active = 1;
            end
        end
    else
        RobustArray = [Optimizer.pop(:).Robustness];
        MaxRobust = max(RobustArray);
        MaxRobustID = find(RobustArray == MaxRobust);
        if Optimizer.QuickRecoveryFlag == 1 && ~isempty(find([Optimizer.pop(MaxRobustID).SpatialSize] > Optimizer.SleepLimit,1))%Quick Mode
            for ii = MaxRobustID
                if Optimizer.pop(ii).SpatialSize > Optimizer.SleepLimit
                    Optimizer.pop(ii).Active = 1;
                end
            end
        else%Normal Mode
            if Optimizer.QuickRecoveryFlag == 1%所有最大鲁棒值的子种群均已collapsed，则执行普通模式
                Optimizer.QuickRecoveryFlag = 0;
            end
            TmpArray1 = find([Optimizer.pop(:).SpatialSize] > Optimizer.SleepLimit);%SS > Rmin
            TmpArray2 = find([Optimizer.pop(TmpArray1).SpatialSize] > Optimizer.CoverLimit);%SS > Rcover
            for ii = TmpArray1(TmpArray2)
                Optimizer.pop(ii).Active = 1;
            end
            TmpArray1(TmpArray2) = [];
            for ii = TmpArray1
                Probability = Optimizer.pop(ii).Robustness / MaxRobust;
                if rand <= Probability
                    Optimizer.pop(ii).Active = 1;
                end
            end
        end
    end
end

