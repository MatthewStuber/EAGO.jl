# Copyright (c) 2018: Matthew Wilhelm & Matthew Stuber.
# This work is licensed under the Creative Commons Attribution-NonCommercial-
# ShareAlike 4.0 International License. To view a copy of this license, visit
# http://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to Creative
# Commons, PO Box 1866, Mountain View, CA 94042, USA.
#############################################################################
# EAGO
# A development environment for robust and global optimization
# See https://github.com/PSORLab/EAGO.jl
#############################################################################
# src/eago_optimizer/evaluator/passes.jl
# Functions used to compute reverse pass of nonlinear functions.
#############################################################################

# maximum number to perform reverse operation on associative term by summing
# and evaluating pairs remaining terms not reversed
const MAX_ASSOCIATIVE_REVERSE = 6

# INSIDE DONE...
function reverse_plus_binary!()

    # extract values for k
    argk_index = @inbounds children_arr[k]
    argk_is_number = @inbounds numvalued[k]
    setk = @inbounds setstorage[argk_index]

    # get row indices
    idx1 = first(children_idx)
    idx2 = last(children_idx)

    # extract values for argument 1
    arg1_index = @inbounds children_arr[idx1]
    arg1_is_number = @inbounds numvalued[arg1_index]
    if arg1_is_number
        set1 = zero(MC{N,T})
        num1 = @inbounds numberstorage[arg1_index]
    else
        num1 = 0.0
        set1 = @inbounds setstorage[arg1_index]
    end

    # extract values for argument 2
    arg2_index = @inbounds children_arr[idx2]
    arg2_is_number = @inbounds numvalued[arg2_index]
    if arg2_is_number
        num2 = @inbounds numberstorage[arg2_index]
        set2 = zero(MC{N,T})
    else
        set2 = @inbounds setstorage[arg2_index]
        num2 = 0.0
    end

    if !arg1_is_number && arg2_is_number
        c, a, b = plus_rev(setk, set1, num2)

    elseif arg1_is_number && !arg2_is_number
        c, a, b  = plus_rev(setk, num1, set2)

    else
        c, a, b  = plus_rev(setk, set1, set2)
    end

    if !arg1_is_number
        if isempty(a)
            return false
        elseif isnan(a)
            a = MC{N,T}(set1.Intv)
        end
        @inbounds setstorage[arg1_index] = is_post ? set_value_post(x, a, lbd, ubd) : a
    end

    if !arg2_is_number
        if isempty(b)
            return false
        elseif isnan(b)
            b = MC{N,T}(set2.Intv)
        end
        @inbounds setstorage[arg2_index] = is_post ? set_value_post(x, b, lbd, ubd) : b
    end

    return true
end

function reverse_plus_narity!()

    child_arr_indx = children_arr[children_idx]
    continue_flag = true

    # out loops makes a temporary sum (minus one argument)
    # a reverse is then compute with respect to this argument
    active_count_number = 0
    for active_idx in child_arr_indx

        # don't contract a number valued argument
        active_arg_is_number = @inbounds numvalued[active_idx]
        active_arg_is_number && continue

        if active_count_number >= MAX_ASSOCIATIVE_REVERSE
            break
        end

        tmp_sum = zero(MC{N,T})
        active_count_number += 1
        for inactive_idx in child_arr_indx
            if inactive_idx != active_idx
                if @inbounds numvalued[inactive_idx]
                    tmp_sum += @inbounds numberstorage[inactive_idx]
                else
                    tmp_sum += @inbounds setstorage[inactive_idx]
                end
            end
        end

        active_set = @inbounds setstorage[active_idx]
        c, a, b = plus_rev(parent_value, active_set, tmp_sum)

        if isempty(a)
            return false
        elseif isnan(a)
            a = MC{N,T}(active_set.Intv)
        end
        @inbounds setstorage[active_idx] = is_post ? set_value_post(x, a, lbd, ubd) : a
    end

    !continue_flag && break
    return true
end

function reverse_multiply_binary!()

    # extract values for k
    argk_index = @inbounds children_arr[k]
    argk_is_number = @inbounds numvalued[k]
    setk = @inbounds setstorage[argk_index]

    # get row indices
    idx1 = first(children_idx)
    idx2 = last(children_idx)

    # extract values for argument 1
    arg1_index = @inbounds children_arr[idx1]
    arg1_is_number = @inbounds numvalued[arg1_index]
    if arg1_is_number
        set1 = zero(MC{N,T})
        num1 = @inbounds numberstorage[arg1_index]
    else
        num1 = 0.0
        set1 = @inbounds setstorage[arg1_index]
    end

    # extract values for argument 2
    arg2_index = @inbounds children_arr[idx2]
    arg2_is_number = @inbounds numvalued[arg2_index]
    if arg2_is_number
        num2 = @inbounds numberstorage[arg2_index]
        set2 = zero(MC{N,T})
    else
        set2 = @inbounds setstorage[arg2_index]
        num2 = 0.0
    end

    if !arg1_is_number && arg2_is_number
        c, a, b = mult_rev(setk, set1, num2)

    elseif arg1_is_number && !arg2_is_number
        c, a, b = mult_rev(setk, num1, set2)

    else
        c, a, b = mult_rev(setk, set1, set2)
    end

    if !arg1_is_number
        if isempty(a)
            return false
        elseif isnan(a)
            a = MC{N,T}(set1.Intv)
        end
        @inbounds setstorage[arg1_index] = is_post ? set_value_post(x, a, lbd, ubd) : a
    end

    if !arg2_is_number
        if isempty(b)
            return false
        elseif isnan(b)
            b = MC{N,T}(set2.Intv)
        end
        @inbounds setstorage[arg2_index] = is_post ? set_value_post(x, b, lbd, ubd) : b
    end

    return true
end

function reverse_multiply_narity!()

    child_arr_indx = children_arr[children_idx]
    continue_flag = true

    # out loops makes a temporary sum (minus one argument)
    # a reverse is then compute with respect to this argument
    active_count_number = 0
    for active_idx in child_arr_indx

        # don't contract a number valued argument
        active_arg_is_number = @inbounds numvalued[active_idx]
        active_arg_is_number && continue

        if active_count_number >= MAX_ASSOCIATIVE_REVERSE
            break
        end

        tmp_mul = one(MC{N,T})
        active_count_number += 1
        for inactive_idx in child_arr_indx
            if inactive_idx != active_idx
                if @inbounds numvalued[inactive_idx]
                    tmp_mul *= @inbounds numberstorage[inactive_idx]
                else
                    tmp_mul *= @inbounds setstorage[inactive_idx]
                end
            end
        end

        active_set = @inbounds setstorage[active_idx]
        c, a, b = mult_rev(parent_value, active_set, tmp_mul)

        if isempty(a)
            return false
        elseif isnan(a)
            a = MC{N,T}(active_set.Intv)
        end
        @inbounds setstorage[active_idx] = is_post ? set_value_post(x, a, lbd, ubd) : a
    end

    !continue_flag && break
    return true
end

function reverse_minus!()

    # extract values for k
    argk_index = @inbounds children_arr[k]
    argk_is_number = @inbounds numvalued[k]
    if !argk_is_number
        setk = @inbounds setstorage[argk_index]
    end

    # don't perform a reverse pass if the output was a number
    if argk_is_number
        return true
    end

    # get row indices
    idx1 = first(children_idx)
    idx2 = last(children_idx)

    # extract values for argument 1
    arg1_index = @inbounds children_arr[idx1]
    arg1_is_number = @inbounds numvalued[arg1_index]
    if arg1_is_number
        set1 = zero(MC{N,T})
        num1 = @inbounds numberstorage[arg1_index]
    else
        num1 = 0.0
        set1 = @inbounds setstorage[arg1_index]
    end

    # extract values for argument 2
    arg2_index = @inbounds children_arr[idx2]
    arg2_is_number = @inbounds numvalued[arg2_index]
    if arg2_is_number
        num2 = @inbounds numberstorage[arg2_index]
        set2 = zero(MC{N,T})
    else
        set2 = @inbounds setstorage[arg2_index]
        num2 = 0.0
    end

    if !arg1_is_number && arg2_is_number
        c, a, b = minus_rev(setk, set1, num2)

    elseif arg1_is_number && !arg2_is_number
        c, a, b = minus_rev(setk, num1, set2)

    else
        c, a, b = minus_rev(setk, set1, set2)
    end

    if !arg1_is_number
        if isempty(a)
            return false
        elseif isnan(a)
            a = MC{N,T}(set1.Intv)
        end
        @inbounds setstorage[arg1_index] = is_post ? set_value_post(x, a, lbd, ubd) : a
    end

    if !arg2_is_number
        if isempty(b)
            return false
        elseif isnan(b)
            b = MC{N,T}(set2.Intv)
        end
        @inbounds setstorage[arg2_index] = is_post ? set_value_post(x, b, lbd, ubd) : b
    end

    return true
end

function reverse_power!()

    # extract values for k
    argk_index = @inbounds children_arr[k]
    argk_is_number = @inbounds numvalued[k]
    if !argk_is_number
        setk = @inbounds setstorage[argk_index]
    end

    # don't perform a reverse pass if the output was a number
    if argk_is_number
        return true
    end

    # get row indices
    idx1 = first(children_idx)
    idx2 = last(children_idx)

    # extract values for argument 1
    arg1_index = @inbounds children_arr[idx1]
    arg1_is_number = @inbounds numvalued[arg1_index]
    if arg1_is_number
        set1 = zero(MC{N,T})
        num1 = @inbounds numberstorage[arg1_index]
    else
        num1 = 0.0
        set1 = @inbounds setstorage[arg1_index]
    end

    # extract values for argument 2
    arg2_index = @inbounds children_arr[idx2]
    arg2_is_number = @inbounds numvalued[arg2_index]
    if arg2_is_number
        num2 = @inbounds numberstorage[arg2_index]
        set2 = zero(MC{N,T})
    else
        set2 = @inbounds setstorage[arg2_index]
        num2 = 0.0
    end

    if !arg1_is_number && arg2_is_number
        c, a, b = power_rev(setk, set1, num2)

    elseif arg1_is_number && !arg2_is_number
        c, a, b = power_rev(setk, num1, set2)

    else
        c, a, b = power_rev(setk, set1, set2)
    end

    if !arg1_is_number
        if isempty(a)
            return false
        elseif isnan(a)
            a = MC{N,T}(set1.Intv)
        end
        @inbounds setstorage[arg1_index] = is_post ? set_value_post(x, a, lbd, ubd) : a
    end

    if !arg2_is_number
        if isempty(b)
            return false
        elseif isnan(b)
            b = MC{N,T}(set2.Intv)
        end
        @inbounds setstorage[arg2_index] = is_post ? set_value_post(x, b, lbd, ubd) : b
    end

    return true
end

function reverse_divide!()

    # extract values for k
    argk_index = @inbounds children_arr[k]
    argk_is_number = @inbounds numvalued[k]
    if !argk_is_number
        setk = @inbounds setstorage[argk_index]
    end

    # don't perform a reverse pass if the output was a number
    if argk_is_number
        return true
    end

    # get row indices
    idx1 = first(children_idx)
    idx2 = last(children_idx)

    # extract values for argument 1
    arg1_index = @inbounds children_arr[idx1]
    arg1_is_number = @inbounds numvalued[arg1_index]
    if arg1_is_number
        set1 = zero(MC{N,T})
        num1 = @inbounds numberstorage[arg1_index]
    else
        num1 = 0.0
        set1 = @inbounds setstorage[arg1_index]
    end

    # extract values for argument 2
    arg2_index = @inbounds children_arr[idx2]
    arg2_is_number = @inbounds numvalued[arg2_index]
    if arg2_is_number
        num2 = @inbounds numberstorage[arg2_index]
        set2 = zero(MC{N,T})
    else
        set2 = @inbounds setstorage[arg2_index]
        num2 = 0.0
    end

    if !arg1_is_number && arg2_is_number
        c, a, b = power_rev(setk, set1, num2)

    elseif arg1_is_number && !arg2_is_number
        c, a, b = power_rev(setk, num1, set2)

    else
        c, a, b = power_rev(setk, set1, set2)
    end

    if !arg1_is_number
        if isempty(a)
            return false
        elseif isnan(a)
            a = MC{N,T}(set1.Intv)
        end
        @inbounds setstorage[arg1_index] = is_post ? set_value_post(x, a, lbd, ubd) : a
    end

    if !arg2_is_number
        if isempty(b)
            return false
        elseif isnan(b)
            b = MC{N,T}(set2.Intv)
        end
        @inbounds setstorage[arg2_index] = is_post ? set_value_post(x, b, lbd, ubd) : b
    end

    return true
end

function reverse_univariate!()
    @inbounds valset = setstorage[k]
    @inbounds argset = setstorage[arg_idx]
    a, b = eval_univariate_set_reverse(op, valset, argset)
    @inbounds setstorage[arg_idx] = is_post ? set_value_post(x, b, lbd, ubd) : b
    return true
end

"""
$(TYPEDSIGNATURES)
"""
function reverse_pass_kernel(setstorage::Vector{T}, numberstorage, numvalued, subexpression_isnum,
                             subexpr_values_set, nd::Vector{JuMP.NodeData}, adj, x_values, current_node::NodeBB,
                             subgrad_tighten::Bool) where T

    children_arr = rowvals(adj)
    N = length(x_values)

    tmp_hold = zero(T)
    continue_flag = true

    for k = 1:length(nd)

        @inbounds nod = nd[k]
        ntype = nod.nodetype
        nvalued = @inbounds numvalued[k]

        if ntype == JuMP._Derivatives.VALUE      || ntype == JuMP._Derivatives.LOGIC     ||
           ntype == JuMP._Derivatives.COMPARISON || ntype == JuMP._Derivatives.PARAMETER ||
           ntype == JuMP._Derivatives.EXTRA
           continue

        elseif nod.nodetype == JuMP._Derivatives.VARIABLE
            op = nod.index
            @inbounds current_node.lower_variable_bounds[op] = setstorage[k].Intv.lo
            @inbounds current_node.upper_variable_bounds[op] = setstorage[k].Intv.hi

        elseif nod.nodetype == JuMP._Derivatives.SUBEXPRESSION
            #=
            @inbounds isnum = subexpression_isnum[nod.index]
            if ~isnum
                @inbounds subexpr_values_set[nod.index] = setstorage[k]
            end          # DONE
            =#

        elseif nvalued
            continue

        elseif nod.nodetype == JuMP._Derivatives.CALL
            op = nod.index
            parent_index = nod.parent
            @inbounds children_idx = nzrange(adj,k)
            @inbounds parent_value = setstorage[k]
            n_children = length(children_idx)

            # SKIPS USER DEFINE OPERATORS NOT BRIDGED INTO JuMP Tree Representation
            if op >= JuMP._Derivatives.USER_OPERATOR_ID_START
                continue

            # :+
            elseif op === 1
                if n_children === 2
                    continue_flag &= reverse_plus_binary!()
                else
                    continue_flag &= reverse_plus_narity!()
                end

            # :-
            elseif op === 2
                continue_flag &= reverse_minus!()

            elseif op === 3 # :*
                if n_children === 2
                    continue_flag &= reverse_multiply_binary!()
                else
                    continue_flag &= reverse_multiply_narity!()
                end

             # :^
            elseif op === 4
                continue_flag &= reverse_power!()

            # :/
            elseif op === 5
                continue_flag &= reverse_divide!()

            elseif op == 6 # ifelse
                continue
            end

        # assumes that child is set-valued and thus parent is set-valued (since isnumber already checked)
        elseif nod.nodetype == JuMP._Derivatives.CALLUNIVAR
            op = nod.index
            if op <= JuMP._Derivatives.USER_UNIVAR_OPERATOR_ID_START
                child_idx = @inbounds children_arr[adj.colptr[k]]
                continue_flag &= reverse_univariate!()
            end
        end

        !continue_flag && break
    end

    return continue_flag
end