library(pomp)


args <- commandArgs(trailingOnly = TRUE)
guessnum <- as.numeric(args[1])

guesses <- readRDS("./guesses.rds")
vpC <- readRDS("./vpC.rds")

# Define the dmeasure component (measurement density)
dmeas <- Csnippet("
  lik = dpois(pop, b*N, give_log);
")

cat("Running mif2 for guess", guessnum, "\n")

mif_result <- mif2(
  data = vpC,  # Your pomp model object
  params = guesses[guessnum, ],
  Np = 1000,  # Number of particles
  Nmif = 20,  # Number of mif2 iterations
  dmeasure = dmeas,
  partrans = parameter_trans(log = c("r", "K", "sigma", "N_0")),
  rw.sd = rw_sd(r = 0.02, K = 0.02, sigma = 0.02, N_0 = ivp(0.02)),
  cooling.fraction.50 = 0.5,
  paramnames = c("r", "K", "sigma", "N_0", "b"),
  statenames = c("N")
)
  
save(mif_result, file = paste0("mif_result_", guessnum, ".RData"))

# After mif2, run pfilter to refine the estimates
cat("Running pfilter for mif_result of guess", guessnum, "\n")

pfilter_result <- pfilter(mif_result, userdata = list(Nrep = 5))

# Save the pfilter result and log likelihood
save(pfilter_result, file = paste0("mif_pfilter_result_", guessnum, ".RData"))