using GeometricMedicalPhantoms
using BenchmarkTools

nx, ny, nz = 128, 128, 128
fov = (30.0, 30.0, 30.0)

fs = 100.0 # 1/fs = 10 ms time resolution
duration = 10 # seconds
respiratory_rate = 12.0 # breaths per minute
heart_rate = 70.0 # beats per minute

t, resp = generate_respiratory_signal(duration, fs, respiratory_rate)
_, vols = generate_cardiac_signals(duration, fs, heart_rate)

phantom = create_torso_phantom(nx, ny, nz;
    fov=fov,
    respiratory_signal=resp,
    cardiac_volumes=vols)


