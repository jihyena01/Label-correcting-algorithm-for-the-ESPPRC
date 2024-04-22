function ==(label1::Label, label2::Label)
    return label1.demand == label2.demand && label1.S == label2.S && label1.v == label2.v && label1.cost == label2.cost && label1.visited == label2.visited
end

function EUD_2D(coordinates)
    dist = zeros(length(coordinates), length(coordinates))
    for i in 1:(length(coordinates)-1)
        for j in i+1 : (length(coordinates))
            dist[i, j] = round(sqrt((coordinates[i][1] - coordinates[j][1])^2 + (coordinates[i][2] - coordinates[j][2])^2))
            dist[j, i] = dist[i, j]
        end
    end
    return dist
end

function get_dual_dist(distance, dual_var, α)
    cost_matrix = zeros(size(distance))
    dual_var = α * dual_var
    node = length(distance[1,:])
    for i in 1: (node-1)
        for j in i+1:node
            cost_matrix[i,j] = distance[i,j] - dual_var[i] # (c_ij - lambda_i)
            cost_matrix[j,i] = distance[j,i] - dual_var[j]
        end
    end
    return cost_matrix
end

function extend_label(label::Label, current_node::Int, next_node::Int, demands::Array{Int64,1}, cost::Array{Float64,2}, capacity::Int)
    current_label = deepcopy(label)
    new_cost = current_label.cost + cost[current_node, next_node]
    new_demand = current_label.demand + demands[next_node]
    new_v = deepcopy(current_label.v)
    new_v[next_node] = 1
    new_visited = deepcopy(current_label.visited)
    # 방문 경로 표기
    visit_order = maximum(current_label.visited) +1
    new_visited[next_node] = visit_order

    if new_demand > capacity
        return nothing
    end
    # unreachable일 경우 포함
    # label.v[i] for i in 1:length(vertex)
    for i in 1:length(demands)
        if new_v[i] == 0 
            calculate_cost = new_demand + demands[i]
            if calculate_cost > capacity
                new_v[i] = 1 # unreachable for resource constraint
            end
        end
    end
    new_S = length(findall(new_v .== 1))
    return Label(new_demand, new_S, new_v, new_cost, new_visited)
end


function find_possible_paths_revised(vertex, labels_per_node, ended_path, current_node, demands, cost, capacity)
    # possible_labels_per_node = Dict{Int, Vector{Label}}()
    current_label = labels_per_node[current_node]
    for label in current_label
        for j in vertex
            if label.v[j] == 0
                new_label = extend_label(label, current_node, j, demands, cost, capacity)
                # println("j num : " , j, new_label)
                
                if new_label !== nothing
                    if all(new_label.v[i] == 1 for i in vertex)
                        push!(ended_path, new_label)
                        continue # 해당 label 제거되면 다음 j로 넘어가야 함!
                    else
                        if haskey(possible_labels_per_node, j)
                            if new_label in possible_labels_per_node[j]
                                continue
                            end
                            possible_labels_per_node[j] = vcat(possible_labels_per_node[j], new_label)
                            
                        else
                            possible_labels_per_node[j] = [new_label]
                            
                        end

                    end
                end
            end
        end
    end

    unique_labels = Dict{Int, Vector{Label}}()
    for (node, labels) in possible_labels_per_node
        unique_labels[node] = Label[]
        for label in labels
            if !(label in unique_labels[node])
                push!(unique_labels[node], label)
            end
        end
    end

    return unique_labels, ended_path
end

function dominance_check(vertex::Array{Int64,1}, labels_per_node::Dict{Int, Vector{Label}})
    for node in keys(labels_per_node)
        current_labels = labels_per_node[node]
        
        nondominated_labels = Label[]

        for label1 in current_labels
            dominated = false
            for label2 in current_labels
                if label1 != label2 && dominates(label2, label1, vertex)
                    dominated = true
                    
                    break
                end
            end
            if !dominated
                push!(nondominated_labels, label1)
            end
        end
        labels_per_node[node] = nondominated_labels
    end
    return labels_per_node
end

function dominates(label1::Label, label2::Label, vertex::Array{Int64,1})
    all_better_or_equal = (label1.cost <= label2.cost) && (label1.demand <= label2.demand) && all(label1.v[i] <= label2.v[i] for i in vertex)
    any_strictly_better = (label1.cost < label2.cost) || (label1.demand < label2.demand) || any(label1.v[i] < label2.v[i] for i in vertex)
    return all_better_or_equal && any_strictly_better
end



function find_changed_keys(updated_labels_per_node::Dict{Int, Vector{Label}}, labels_per_node::Dict{Int, Vector{Label}})
    changed_keys = []
    for key in union(keys(updated_labels_per_node), keys(labels_per_node))
        if get(updated_labels_per_node, key, nothing) != get(labels_per_node, key, nothing)
            push!(changed_keys, key)
        end
    end
    return changed_keys
end