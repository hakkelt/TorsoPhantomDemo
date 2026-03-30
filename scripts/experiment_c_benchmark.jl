using BenchmarkTools

include(joinpath(@__DIR__, "utils.jl"))

out_dir = ensure_output_dir(joinpath(@__DIR__, "..", "output"))
project_dir = abspath(joinpath(@__DIR__, ".."))

sizes = [128, 256]
threads_list = [1, 2, 4, 8]

results = []

function run_belapsed_3d(n, nt, threads, project_dir)
    code = """
    using GeometricMedicalPhantoms
    using BenchmarkTools
    using ThreadPinning
    pinthreads(:cores)
    n = $n
    nt = $nt
    _, resp = generate_respiratory_signal(nt, 1.0, 12.0)
    _, vols = generate_cardiac_signals(nt, 1.0, 70.0)
    t = @belapsed create_torso_phantom(\$n, \$n, \$n; respiratory_signal=\$resp, cardiac_volumes=\$vols) seconds=60
    println(t)
    """
    cmd = `$(Base.julia_cmd()) --project=$project_dir --threads=$threads,0 -e $code`
    output = read(cmd, String)
    return parse(Float64, strip(output))
end

function run_belapsed_2d(n, nt, threads, project_dir)
    code = """
    using GeometricMedicalPhantoms
    using BenchmarkTools
    using ThreadPinning
    pinthreads(:cores)
    BenchmarkTools.DEFAULT_PARAMETERS.seconds = 60
    n = $n
    nt = $nt
    _, resp = generate_respiratory_signal(nt, 1.0, 12.0)
    _, vols = generate_cardiac_signals(nt, 1.0, 70.0)
    t = @belapsed create_torso_phantom(\$n, \$n, :axial; slice_position=0.0, respiratory_signal=\$resp, cardiac_volumes=\$vols)
    println(t)
    """
    cmd = `$(Base.julia_cmd()) --project=$project_dir --threads=$threads,0 -e $code`
    output = read(cmd, String)
    return parse(Float64, strip(output))
end

function format_time(t)
    return if t < 1e-3
        "$(round(t * 1e6; digits=3)) μs"
    elseif t < 1.0
        "$(round(t * 1e3; digits=3)) ms"
    else
        "$(round(t; digits=3)) s"
    end
end

function print_time(n, nt, threads, t, dim)
    println("$dim $(n)^$(dim == "2D" ? 2 : 3), frames=$(nt), threads=$(threads): $(format_time(t))")
end

for n in sizes
    threads = 1
    t2d = run_belapsed_2d(n, 1, threads, project_dir)
    push!(results, (dim="2D", grid="$(n)^2", frames=1, threads=threads, time=t2d))
    print_time(n, 1, threads, t2d, "2D")

    for threads in threads_list
        t2d = run_belapsed_2d(n, 100, threads, project_dir)
        push!(results, (dim="2D", grid="$(n)^2", frames=100, threads=threads, time=t2d))
        print_time(n, 100, threads, t2d, "2D")
    end

    threads = 1
    t3d = run_belapsed_3d(n, 1, threads, project_dir)
    push!(results, (dim="3D", grid="$(n)^3", frames=1, threads=threads, time=t3d))
    print_time(n, 1, threads, t3d, "3D")

    for threads in threads_list
        t3d = run_belapsed_3d(n, 100, threads, project_dir)
        push!(results, (dim="3D", grid="$(n)^3", frames=100, threads=threads, time=t3d))
        print_time(n, 100, threads, t3d, "3D")
    end
end

csv_path = joinpath(out_dir, "experiment_c_benchmark.csv")
open(csv_path, "w") do io
    println(io, "dimension,grid_size,time_frames,threads,total_seconds")
    for r in results
        println(io, "$(r.dim),$(r.grid),$(r.frames),$(r.threads),$(r.time)")
    end
end

md_path = joinpath(out_dir, "experiment_c_benchmark.md")
open(md_path, "w") do io
    println(io, "# Experiment C: Performance Benchmarking")
    println(io, "")
    println(io, "Generates a full 4D dataset in seconds.")
    println(io, "")
    println(io, "| Dimension | Grid Size | Time Frames | Threads | Total Generation Time |")
    println(io, "|---|---:|---:|---:|---:|")
    for r in results
        println(io, "| $(r.dim) | $(r.grid) | $(r.frames) | $(r.threads) | $(format_time(r.time)) |")
    end
end

println("Saved benchmark table to:")
println("  " * csv_path)
println("  " * md_path)
