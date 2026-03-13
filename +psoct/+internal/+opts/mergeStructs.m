function out = mergeStructs(base, override)
%MERGESTRUCTS Merge two structs with override precedence.
%
%   out = psoct.internal.opts.mergeStructs(base, override)
%
%   - If either input is empty, it is treated as an empty struct().
%   - All fields from BASE are copied into OUT.
%   - All fields from OVERRIDE are then copied into OUT, overwriting any
%     existing fields from BASE with the same name.

if isempty(base)
    base = struct();
end
if isempty(override)
    override = struct();
end

out = base;
fn = fieldnames(override);
for k = 1:numel(fn)
    out.(fn{k}) = override.(fn{k});
end

end

