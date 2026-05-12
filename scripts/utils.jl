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

function panel_label(i)
    return string(Char('A' + i - 1))
end

function annotate_panel_labels!(plt, fontsize, x_shift, y_shift, plot_indices=1:length(plt))
    for i in plot_indices
        xl = xlims(plt[i])
        yl = ylims(plt[i])
        x = xl[1] + x_shift * (xl[2] - xl[1])
        y = yl[1] + y_shift * (yl[2] - yl[1])
        annotate!(plt[i], x, y, text(panel_label(i), font(fontsize, "Helvetica Bold", :left, :top)))
    end
end
