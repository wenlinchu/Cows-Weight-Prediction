function y = safeFirstElement(x)
    if isempty(x)
        y = NaN;
    else
        y = x(1);
    end
end