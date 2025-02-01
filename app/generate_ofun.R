# generate_ofun.R

# Load Libraries
library(pomp)

# Define C Snippets
Csnippet("
  pop = rpois(b*N);  
") -> rmeas

Csnippet("
  N = N_0;
") -> rinit


Csnippet("
  double dW = rnorm(0,sqrt(dt));
  N += r*N*(1-N/K)*dt+sigma*N*dW;
") -> vpstepC

# Create the pomp object

parus |>
  pomp(
    times="year", t0=1960,
    rinit=rinit,
    rmeasure=rmeas,
    rprocess=euler(vpstepC, delta.t=1/365),
    statenames="N",
    paramnames=c("r", "K", "sigma", "b", "N_0")
  ) -> vpC

# Define the deterministic skeleton

vpC |>
  pomp(
    skeleton=vectorfield(Csnippet("DN = r*N*(1-N/K);")),
    paramnames=c("r","K"), statenames="N"
  ) -> vpC

# Define the dmeasure component (measurement density)
dmeas <- Csnippet("
  lik = dpois(pop, b*N, give_log);
")

# Create an objective function for the Verhulst-Pearl model
vpC |>
  traj_objfun(
    est=c("K", "N_0"),
    params=c(r=0.5, K=2000, sigma=0.1, b=0.1, N_0=2000),
    dmeasure=dmeas, statenames="N", paramnames="b"
  ) -> ofun

# Save the objective function as an RDS object
saveRDS(ofun, file = "./ofun.rds")