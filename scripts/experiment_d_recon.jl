using GeometricMedicalPhantoms
using FFTW
using Plots

include(joinpath(@__DIR__, "utils.jl"))

out_dir = ensure_output_dir(joinpath(@__DIR__, "..", "output"))

# Acquisition parameters (2D coronal)
nx = 256
ny = 256

fs = 200.0
tr = 0.05
frames_per_tr = round(Int, tr * fs)
lines = ny

duration = tr * lines
rr_bpm = 12.0
hr_bpm = 70.0

println("Generating 2D dynamic phantom...")
t, resp = generate_respiratory_signal(duration, fs, rr_bpm)
_, vols = generate_cardiac_signals(duration, fs, hr_bpm)

phantom = create_torso_phantom(nx, ny, :coronal; respiratory_signal=resp, cardiac_volumes=vols)

# Build blurred frames: average 5 frames per TR
num_tr = lines
blurred = Array{Float64}(undef, nx, ny, num_tr)
for i in 1:num_tr
    i1 = (i - 1) * frames_per_tr + 1
    i2 = min(i * frames_per_tr, size(phantom, 3))
    slice_accum = zeros(Float64, nx, ny)
    for k in i1:i2
        slice_accum .+= abs.(phantom[:, :, k])
    end
    blurred[:, :, i] = slice_accum ./ (i2 - i1 + 1)
end

ground_truth = abs.(phantom[:, :, size(phantom, 3) ÷ 2])

println("Simulating Cartesian line-by-line acquisition...")
kspace_cart = zeros(ComplexF64, nx, ny)
for i in 1:ny
    img = blurred[:, :, i]
    ksp = fft(ComplexF64.(img))
    kspace_cart[:, i] = ksp[:, i]
end
recon_cart = abs.(ifft(kspace_cart))

# Scale Cartesian reconstruction to minimize MSE vs ground truth
scale_num = sum(ground_truth .* recon_cart)
scale_den = sum(recon_cart .* recon_cart)
scale = scale_den == 0 ? 1.0 : scale_num / scale_den
recon_cart_scaled = recon_cart .* scale
mse_cart = mean((recon_cart_scaled .- ground_truth) .^ 2)
println("Cartesian scaling factor: ", round(scale; digits=6))
println("Cartesian MSE after scaling: ", round(mse_cart; digits=8))

error_map = abs.(recon_cart_scaled .- ground_truth)

println("Rendering combined output figure...")
p = plot(layout=(1, 3), size=(1500, 500), margin=8Plots.mm)
heatmap!(p[1], ground_truth'; c=:grays, axis=nothing, colorbar=false, aspect_ratio=1, yflip=false,
    title="Ground Truth")
heatmap!(p[2], recon_cart_scaled'; c=:grays, axis=nothing, colorbar=false, aspect_ratio=1, yflip=false,
    title="Cartesian Reconstruction")
heatmap!(p[3], error_map'; c=:grays, axis=nothing, colorbar=false, aspect_ratio=1, yflip=false,
    title="Absolute Error")

savefig(p, joinpath(out_dir, "experiment_d_comparison.png"))
savefig(p, joinpath(out_dir, "experiment_d_comparison.pdf"))

println("Saved reconstruction results to: " * out_dir)
