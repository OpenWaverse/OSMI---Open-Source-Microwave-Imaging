function s = latex_text(s)
% LATEX_TEXT  Escape LaTeX special characters in plain text (e.g. file names).
%
%   latex_text("background_data")   ->  "background\_data"

s = string(s);
for c = ["\", "_", "%", "&", "#", "$", "{", "}"]
    if c == "\"
        s = replace(s, "\", "\textbackslash ");
    else
        s = replace(s, c, "\" + c);
    end
end

end
