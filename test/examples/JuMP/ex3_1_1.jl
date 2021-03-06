using JuMP, EAGO

m = Model(optimizer_with_attributes(EAGO.Optimizer, "verbosity" => 1,
                                                    "output_iterations" => 1000,
                                                    "iteration_limit" => 100000,

                                                    "cp_depth" => -1,
                                                    "cp_repetitions" => -1,
                                                    "cp_forward_reverse_limit" => 2,

                                                    "cut_min_iterations" => 2,
                                                    "cut_max_iterations" => 2,
                                                    "objective_cut_on" => true,
                                                    "subgrad_tighten" => true,

                                                    "obbt_depth" => 6,
                                                    "obbt_repetitions" => 4,
                                                    "obbt_aggressive_on" => true,

                                                    "upper_bounding_depth" => 12,

                                                    "fbbt_lp_depth" => -1,
                                                    "fbbt_lp_repetitions" => 3))

# ----- Variables ----- #
x_Idx = Any[1, 2, 3, 4, 5, 6, 7, 8]
@variable(m, x[x_Idx])

xL = [100.0, 1000.0, 1000.0, 10.0, 10.0, 10.0, 10.0, 10.0]
xU = [10000.0, 10000.0, 10000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0]
for i in 1:8
    JuMP.set_lower_bound(x[i], xL[i])
    JuMP.set_upper_bound(x[i], xU[i])
end


# ----- Constraints ----- #
@constraint(m, e2, 0.0025*x[4]+0.0025*x[6] <= 1.0)
@constraint(m, e3, -0.0025*x[4]+0.0025*x[5]+0.0025*x[7] <= 1.0)
@constraint(m, e4, -0.01*x[5]+0.01*x[8] <= 1.0)
@constraint(m, e5, 100*x[1]-x[1]*x[6]+833.33252*x[4] <= 83333.333)
@constraint(m, e6, x[2]*x[4]-x[2]*x[7]-1250*x[4]+1250*x[5] <= 0.0)
@constraint(m, e7, x[3]*x[5]-x[3]*x[8]-2500*x[5] <= -1.25e6)


# ----- Objective ----- #
@objective(m, Min, x[1]+x[2]+x[3])
JuMP.optimize!(m)

backend_opt = backend(m).optimizer.model.optimizer
last_relaxed_opt = backend_opt.relaxed_optimizer
run_time = backend_opt._run_time
println("run time: $run_time")
