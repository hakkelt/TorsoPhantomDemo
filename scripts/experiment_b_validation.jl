using GeometricMedicalPhantoms
using Plots

include(joinpath(@__DIR__, "utils.jl"))

out_dir = ensure_output_dir(joinpath(@__DIR__, "..", "output"))

function measure_lung_volumes(phantom, fov)
    nt = size(phantom, 4)
    vols = zeros(Float64, nt)
    for i in 1:nt
        frame = phantom[:, :, :, i]
        vols[i] = GeometricMedicalPhantoms.calculate_volume(frame, (0.075f0, 0.11f0), fov)
    end
    return vols
end

function measure_cardiac_volumes(phantom, fov, ti::TissueIntensities)
    nt = size(phantom, 4)
    lv = zeros(Float64, nt)
    rv = zeros(Float64, nt)
    la = zeros(Float64, nt)
    ra = zeros(Float64, nt)
    for i in 1:nt
        frame = phantom[:, :, :, i]
        lv[i] = GeometricMedicalPhantoms.calculate_volume(frame, ti.lv_blood, fov) * 1000.0
        rv[i] = GeometricMedicalPhantoms.calculate_volume(frame, ti.rv_blood, fov) * 1000.0
        la[i] = GeometricMedicalPhantoms.calculate_volume(frame, ti.la_blood, fov) * 1000.0
        ra[i] = GeometricMedicalPhantoms.calculate_volume(frame, ti.ra_blood, fov) * 1000.0
    end
    return (lv=lv, rv=rv, la=la, ra=ra)
end

# Lung volume validation - realistic signal
println("Generating realistic signal lung validation...")
fs = 24.0
duration = 4.0
rr_bpm = 15.0
t, resp_typical = generate_respiratory_signal(duration, fs, rr_bpm)

nx = 128
ny = 128
nz = 128
fov = (30, 30, 30)

phantom_typical = create_torso_phantom(nx, ny, nz; respiratory_signal=resp_typical)
measured_typical = measure_lung_volumes(phantom_typical, fov)
resp_typical_ml = resp_typical .* 1000.0
measured_typical_ml = measured_typical .* 1000.0

# Cardiac chamber volume validation
println("Generating cardiac chamber validation...")
duration = 3.0
fs = 24.0
hr_bpm = 70.0
t_cardiac, vols_cardiac = generate_cardiac_signals(duration, fs, hr_bpm)

phantom_cardiac = create_torso_phantom(nx, ny, nz; cardiac_volumes=vols_cardiac)
ti = TissueIntensities()
measured_cardiac = measure_cardiac_volumes(phantom_cardiac, fov, ti)

layout = @layout [a{0.38w} [b c; d e]]
title_fontsize = 20
combined_plot = plot(
    layout=layout,
    size=(1600, 900),
    margin=4Plots.mm,
    titlefontsize=title_fontsize,
    guidefontsize=16,
    tickfontsize=14,
    legendfontsize=14,
)

plot!(combined_plot[1], t, resp_typical_ml; label="Expected", color=:green, linewidth=2,
    xlabel="Time (s)", ylabel="Lung Volume (mL)", title="Lung Volume", legend=:topright,
    left_margin=16Plots.mm, bottom_margin=8Plots.mm)
plot!(combined_plot[1], t, measured_typical_ml; label="Measured", color=:deeppink, linewidth=2)

plot!(combined_plot[2], t_cardiac, vols_cardiac.lv; label=false, color=:green, linewidth=2,
    xlabel="Time (s)", ylabel="Volume (mL)", title="Left Ventricle Volume", legend=false,
    left_margin=12Plots.mm, bottom_margin=12Plots.mm)
plot!(combined_plot[2], t_cardiac, measured_cardiac.lv; label=false, color=:deeppink, linewidth=2)
plot!(combined_plot[3], t_cardiac, vols_cardiac.rv; label=false, color=:green, linewidth=2,
    xlabel="Time (s)", ylabel="Volume (mL)", title="Right Ventricle Volume", legend=false,
    left_margin=12Plots.mm, bottom_margin=12Plots.mm)
plot!(combined_plot[3], t_cardiac, measured_cardiac.rv; label=false, color=:deeppink, linewidth=2)
plot!(combined_plot[4], t_cardiac, vols_cardiac.la; label=false, color=:green, linewidth=2,
    xlabel="Time (s)", ylabel="Volume (mL)", title="Left Atrium Volume", legend=false,
    top_margin=8Plots.mm, left_margin=12Plots.mm, bottom_margin=4Plots.mm)
plot!(combined_plot[4], t_cardiac, measured_cardiac.la; label=false, color=:deeppink, linewidth=2)
plot!(combined_plot[5], t_cardiac, vols_cardiac.ra; label=false, color=:green, linewidth=2,
    xlabel="Time (s)", ylabel="Volume (mL)", title="Right Atrium Volume", legend=false,
    top_margin=8Plots.mm, left_margin=12Plots.mm, bottom_margin=4Plots.mm)
plot!(combined_plot[5], t_cardiac, measured_cardiac.ra; label=false, color=:deeppink, linewidth=2)
annotate_panel_labels!(combined_plot, title_fontsize, -0.15, 1.05, 1:1)
annotate_panel_labels!(combined_plot, title_fontsize, -0.15, 1.15, 2:3)
annotate_panel_labels!(combined_plot, title_fontsize, -0.15, 1.20, 4:5)

combined_png = joinpath(out_dir, "experiment_b_realistic_plus_cardiac.png")
combined_pdf = joinpath(out_dir, "experiment_b_realistic_plus_cardiac.pdf")
savefig(combined_plot, combined_png)
savefig(combined_plot, combined_pdf)

println("Saved validation plots to: " * out_dir)
