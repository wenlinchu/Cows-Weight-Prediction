function tmpData = interpolateStructFields(tmpData, var)
    % 遍歷 tmpData 的所有欄位並對數值欄位進行 NaN 插值
    fn1 = fieldnames(tmpData);
    
    for i = 1:length(fn1)
        fn2 = fieldnames(tmpData.(fn1{i}));
        
        for j = 1:length(fn2)
            fn3 = fieldnames(tmpData.(fn1{i}).(fn2{j}));
            
            for k = 1:length(fn3)-2
                data = {tmpData.(fn1{i}).(fn2{j}).(fn3{k})}';
                
                % 轉換為數值陣列，將空值轉換為 NaN 以便插值
                numData = cellfun(@safeFirstElement, data);
                
                if any(~isnan(numData)) % 確保有數據可用於插值
                    numericData = inpaint_nans(numData, var);
                else
                    numericData = numData; % 若全為 NaN 則不進行插值
                end
                
                % 將補值後的數據寫回結構體
                for h = 1:length(data)
                    tmpData.(fn1{i}).(fn2{j})(h).(fn3{k}) = numericData(h);
                end
            end
        end
    end
end
