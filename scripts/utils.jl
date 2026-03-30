function ensure_output_dir(out_dir::AbstractString)
    isdir(out_dir) || mkpath(out_dir)
    return out_dir
end

function pick_time_indices(t::AbstractVector{<:Real}, targets::AbstractVector{<:Real})
    idx = similar(targets, Int)
    for (i, tt) in enumerate(targets)
        j = findmin(abs.(t .- tt))[2]
        idx[i] = j
    end
    return idx
end

function extract_coronal_slice(volume::AbstractArray, y_index::Int)
    return volume[:, y_index, :]
end

function normalize_frame(frame::AbstractArray)
    max_val = maximum(abs.(frame))
    if max_val == 0
        return zeros(size(frame))
    end
    return abs.(frame) ./ max_val
end
