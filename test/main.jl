include("../src/p-n16-k8.jl")
include("../src/functions.jl")
include("../src/A-n32-k5.jl")
include("../src/B-n64-k9.jl")
using DataStructures
import Base: ==

mutable struct Label
    demand::Int
    S::Int
    v::Array{Int}
    cost::Float64
    visited::Array{Int}
end

function ==(label1::Label, label2::Label)
    return label1.demand == label2.demand && label1.S == label2.S && label1.v == label2.v && label1.cost == label2.cost && label1.visited == label2.visited
end

# coordinates, demands, dual_var, capacity = p_n16_k8()
# coordinates, demands, dual_var, capacity = A_n32_k5()
coordinates, demands, dual_var, capacity = B_n64_k9()

# α = 1.3
# α = 0.8
α = 0.9 

ended_path = labeling_algorithm(coordinates, demands, dual_var, capacity, α)

min_label = argmin(label -> label.cost, ended_path)

count = 0
optimal_path = []
for i in 1:length(min_label.visited)
    if min_label.visited[i] != 0
        count += 1
    end
end

for i in 1:count
    index = findfirst(x->x==i, min_label.visited)
    push!(optimal_path, index)
end
@show optimal_path
optimal_val = min_label.cost + cost[optimal_path[end], 1]