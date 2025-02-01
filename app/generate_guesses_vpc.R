# Load Libraries
library(pomp)

args <- commandArgs(trailingOnly = TRUE)
numguesses <- as.numeric(args[1])

# Define C Snippets
Csnippet("
  pop = rpois(b*N);  
") -> rmeas

Csnippet("
  N = N_0;
") -> rinit

Csnippet("
  double eps = rnorm(0,sigma);
  N = r*N*exp(1-N/K+eps);
") -> rickstepC

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

sobol_design(
  lower=c(r=0, K=100, sigma=0, N_0=150, b=1),
  upper=c(r=5, K=600, sigma=2, N_0=150, b=1),
  nseq=numguesses
) -> guesses

saveRDS(guesses, file = "./guesses.rds")
saveRDS(vpC, file = "./vpC.rds")