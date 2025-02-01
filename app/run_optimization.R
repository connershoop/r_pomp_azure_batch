library(subplex)
library(pomp)

# Load the saved objective function from the RDS file
ofun <- readRDS("./ofun.rds")

# Extract command-line arguments for K and N_0
args <- commandArgs(trailingOnly = TRUE)
K <- as.numeric(args[1])
N_0 <- as.numeric(args[2])

print(sprintf('optimizing objective function with initial params K: %d and N_0: %d', K, N_0))

# Define the initial parameters for optimization
initial_params <- c(K = K, N_0 = N_0)

# Run the subplex optimization algorithm
fit <- subplex(par = initial_params, fn = ofun)

# Save the fit results to a file
save(fit, file = paste0("fit_results_", K, "_", N_0, ".RData"))