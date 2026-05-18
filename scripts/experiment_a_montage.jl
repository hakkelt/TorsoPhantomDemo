using GeometricMedicalPhantoms
using Plots
using Statistics

include(joinpath(@__DIR__, "utils.jl"))

out_dir = ensure_output_dir(joinpath(@__DIR__, "..", "output"))

function select_extreme_indices(resp_signal, heart_signal; target = 5)
    n = length(resp_signal)
    resp_order = sortperm(resp_signal)
    heart_order = sortperm(heart_signal)

    candidates = Int[]
    push!(candidates, resp_order[1])
    push!(candidates, resp_order[end])
    push!(candidates, heart_order[1])
    push!(candidates, heart_order[end])

    idx = unique(candidates)
    if length(idx) < target && n >= 2
        push!(idx, resp_order[2])
        push!(idx, resp_order[end - 1])
        push!(idx, heart_order[2])
        push!(idx, heart_order[end - 1])
        idx = unique(idx)
    end
    if length(idx) < 4
        push!(idx, resp_order[cld(n, 2)])
        idx = unique(idx)
    end

    sort!(idx)
    if length(idx) > target
        idx = idx[1:target]
    end
    return idx
end

function single_frame_cardiac(vols, i)
    return (lv = [vols.lv[i]], rv = [vols.rv[i]], la = [vols.la[i]], ra = [vols.ra[i]])
end

function add_colored_frame!(plt, color, xsize, ysize)
    plot!(plt, [0.5, xsize + 0.5], [0.5, 0.5]; color = color, linewidth = 2, label = false)
    plot!(plt, [0.5, xsize + 0.5], [ysize + 0.5, ysize + 0.5]; color = color, linewidth = 2, label = false)
    plot!(plt, [0.5, 0.5], [0.5, ysize + 0.5]; color = color, linewidth = 2, label = false)
    plot!(plt, [xsize + 0.5, xsize + 0.5], [0.5, ysize + 0.5]; color = color, linewidth = 2, label = false)
end

fs = 100
duration = 5.0
rr_bpm = 12.0
hr_bpm = 70.0

println("Generating physiological signals...")
t, resp = generate_respiratory_signal(duration, fs, rr_bpm, physiology=RespiratoryPhysiology(minL=1.5, maxL=3.5))
_, vols = generate_cardiac_signals(duration, fs, hr_bpm)
nt = length(t)

println("Preparing frame indices from extreme respiratory/cardiac phases...")
heart_total = vols.lv .+ vols.rv .+ vols.la .+ vols.ra
idx = select_extreme_indices(resp, heart_total; target = 5)

nx = 512
ny = 512
nz = 512
mid_z = cld(nz, 2)

println("Generating phantom and mask...")
phantom = create_torso_phantom(nx, ny, :coronal; respiratory_signal=resp, cardiac_volumes=vols)
right_heart_mask = create_torso_phantom(nx, ny, :coronal; ti = TissueMask(rv_blood = true, ra_blood = true))

println("Estimating right-heart center for vertical line...")
mask_slice = right_heart_mask[:, :, 1]
coords = findall(mask_slice)
x_green = if isempty(coords)
    cld(nx, 2)
else
    round(Int, mean(Tuple(c)[1] for c in coords))
end

println("Rendering selected montage frames...")
selected_slices = Vector{Matrix{Float64}}(undef, length(idx))
for (k, i) in enumerate(idx)
    selected_slices[k] = phantom[:, :, i]
end
max_val = maximum(maximum.(selected_slices))

ncols = length(idx)
title_fontsize = 20
montage = plot(
    layout = (1, ncols),
    size = (360 * ncols, 420),
    titlefontsize = title_fontsize,
    guidefontsize = 16,
    tickfontsize = 13,
)
for (k, i) in enumerate(idx)
    img = (selected_slices[k] ./ max_val)'
    heatmap!(montage[k], img;
        c = :grays,
        colorbar = false,
        aspect_ratio = 1,
        yflip = false,
        xlabel = "x",
        ylabel = "z",
        title = "t=$(round(t[i]; digits = 2))s")
end
annotate_panel_labels!(montage, title_fontsize, 0.02, 1.25)

println("Saving montage of selected frames...")
png_path = joinpath(out_dir, "experiment_a_montage.png")
pdf_path = joinpath(out_dir, "experiment_a_montage.pdf")
savefig(montage, png_path)
savefig(montage, pdf_path)

println("Computing line evolution maps...")
line_red = zeros(Float64, nx, nt)
line_green = zeros(Float64, nz, nt)
initial_slice = zeros(Float64, nx, nz)
Threads.@threads for i in 1:nt
    frame = @view phantom[:, :, i]
    if i == 1
        copyto!(initial_slice, frame)
    end
    line_red[:, i] = @view frame[:, mid_z]
    line_green[:, i] = @view frame[x_green, :]
end

red_img = line_red'
green_img = line_green'
initial_img = (initial_slice ./ maximum(initial_slice))'

title_fontsize = 30
println("Rendering line evolution maps...")
line_plot = plot(
    layout = (1, 3),
    size = (1900, 600),
    legend = false,
    margin = 4Plots.mm,
    titlefontsize = title_fontsize,
    guidefontsize = 22,
    tickfontsize = 20,
)
heatmap!(line_plot[1], initial_img;
    c = :grays,
    colorbar = false,
    aspect_ratio = 1,
    yflip = false,
    xlabel = "x",
    ylabel = "z",
    title = "Initial Frame",
    left_margin = 18Plots.mm,
    right_margin = 16Plots.mm,
    bottom_margin = 6Plots.mm)
plot!(line_plot[1], [1, nx], [mid_z, mid_z]; color = :red, linewidth = 2, label = false)
plot!(line_plot[1], [x_green, x_green], [1, nz]; color = :green, linewidth = 2, label = false)

heatmap!(line_plot[2], red_img;
    c = :grays,
    colorbar = false,
    aspect_ratio = :auto,
    yflip = false,
    xlabel = "x",
    ylabel = "time",
    title = "Red Line Evolution",
    right_margin = 16Plots.mm,
    bottom_margin = 14Plots.mm)
add_colored_frame!(line_plot[2], :red, nx, nt)

heatmap!(line_plot[3], green_img';
    c = :grays,
    colorbar = false,
    aspect_ratio = :auto,
    yflip = false,
    xlabel = "time",
    ylabel = "z",
    title = "Green Line Evolution",
    bottom_margin = 0Plots.mm)
add_colored_frame!(line_plot[3], :green, nt, nz)
annotate_panel_labels!(line_plot, title_fontsize, -0.15, 1.10)

println("Saving line evolution maps...")
line_png = joinpath(out_dir, "experiment_a_line_evolution.png")
line_pdf = joinpath(out_dir, "experiment_a_line_evolution.pdf")
savefig(line_plot, line_png)
savefig(line_plot, line_pdf)

println("Saved montage to:")
println("  " * png_path)
println("  " * pdf_path)
println("Saved line evolution to:")
println("  " * line_png)
println("  " * line_pdf)
