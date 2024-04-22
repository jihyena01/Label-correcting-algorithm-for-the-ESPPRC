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


coordinates, demands, dual_var, capacity = p_n16_k8()
# coordinates, demands, dual_var, capacity = A_n32_k5()
# coordinates, demands, dual_var, capacity = B_n64_k9()

α = 1.3
# α = 0.8
# α = 0.9 

## initial setting
distance = EUD_2D(coordinates)
cost = get_dual_dist(distance, dual_var, α)
vertex = collect(1 :length(distance[1,:]))


labels_per_node = Dict{Int, Vector{Label}}()
possible_labels_per_node = Dict{Int, Vector{Label}}()
initial_label = Label(0, 0, zeros(Int, length(vertex)), 0, zeros(Int, length(vertex)))
initial_label.v[1] = 1
initial_label.visited[1] = 1
labels_per_node[1] = [initial_label]
ended_path = Vector{Label}()

d = Deque{Int}()
push!(d, 1)



@time while !isempty(d)
    current_node = popfirst!(d)

    possible_labels_per_node, ended_path = find_possible_paths_revised(vertex, labels_per_node, ended_path, current_node, demands, cost, capacity)
    println("current_node: $current_node")
    println("possible_labels_per_node: $possible_labels_per_node")
    println("ended_path: $ended_path")
    new_labels_per_node = merge((x, y) -> vcat(x, y), labels_per_node, possible_labels_per_node) # F_ij

    unique_labels = Dict{Int, Vector{Label}}()
    for (node, labels) in new_labels_per_node
        unique_labels[node] = Label[]
        for label in labels
            if !(label in unique_labels[node])
                push!(unique_labels[node], label)
            end
        end
    end

    println("unique_labels: $unique_labels")
    updated_labels_per_node = dominance_check(vertex, unique_labels)

    changed_keys = find_changed_keys(updated_labels_per_node, labels_per_node)
    println("updated_labels_per_node: $updated_labels_per_node")
    println("changed_keys: $changed_keys")

    for key in changed_keys
        if !in(key, d)
            push!(d, key)
        end
    end

    
    labels_per_node = updated_labels_per_node

end


min_label = argmin(label -> label.cost, ended_path)
# @show min_label
optimal_path = []
for i in 1:min_label.visited[argmax(min_label.visited)]
    index = findfirst(x->x==i, min_label.visited)
    push!(optimal_path, index)
end

# 마지막 노드 -> depot까지의 경로 합산
optimal_val = min_label.cost + cost[optimal_path[end], 1]

