include("../src/p-n16-k8.jl")
include("../src/functions.jl")
include("../src/A-n32-k5.jl")
include("../src/B-n64-k9.jl")
using DataStructures, Plots
import Base: ==

function ==(label1::Label, label2::Label)
    return label1.demand == label2.demand && label1.S == label2.S && label1.v == label2.v && label1.cost == label2.cost && label1.visited == label2.visited
end
# coordinates, demands, dual_var, capacity = p_n16_k8()
# coordinates, demands, dual_var, capacity = A_n32_k5()
coordinates, demands, dual_var, capacity = B_n64_k9()

α_values = 0.0:0.05:1.0


times = []
final_path_sets = Vector{Label}()
for α in α_values
    start_time = time()
    # algorithm start
    # ----------------------------------------------------------------- #
    ended_path = labeling_algorithm(coordinates, demands, dual_var, capacity, α)
    # ----------------------------------------------------------------- #
    end_time = time()
    min_label = argmin(label -> label.cost, ended_path)
    elapsed_time = end_time - start_time
    push!(final_path_sets, min_label)
    push!(times, elapsed_time)
end

# α 값에 따른 실행 시간 플롯
plot(α_values, times, label="the computational time", xlabel="α", ylabel="time (s)", title="the computational time", lw=2, legend=:topleft, fmt=:png, dpi=150, size=(800, 600))
# savefig("plot(B_n64_k9).png")
optimal_path_sets = []

for label in final_path_sets
    count = 0
    optimal_path = []
    for i in 1:length(label.visited)
        if label.visited[i] != 0
            count += 1
        end
    end

    for i in 1:count
        index = findfirst(x->x==i, label.visited)
        push!(optimal_path, index)
    end
    push!(optimal_path_sets, optimal_path)
    @show optimal_path
end

println("optimal_path_sets: ", optimal_path_sets)