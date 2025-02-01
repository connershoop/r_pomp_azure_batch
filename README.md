# Overview <!-- omit in toc -->

This repository contains two examples demonstrating how to use the [R-POMP package](https://kingaa.github.io/pomp/) for parameter optimization on [Azure Batch](https://azure.microsoft.com/en-us/products/batch). The examples cover **trajectory mapping** and **iterative filtering**, each detailed in its own Jupyter notebook.

Both examples share the `./app` directory for storing scripts and assets. The necessary Azure resources are listed in the **Prerequisites** section below. For more details, refer to the documentation and notebook overviews provided below.

- [Prerequisites](#prerequisites)
- [POMP Trajectory Mapping](#pomp-trajectory-mapping)
- [POMP Iterative Filtering](#pomp-iterative-filtering)

# Prerequisites
1. Python 3.12
   1. Ideally, you already have a Python environment set up or are working on a machine with a single Python environment. If not, I would recommend using a GitHub Codespace built from [this repository's devcontainer.](./.devcontainer/devcontainer.json))
2. An azure resource group
   1. An azure batch account
      1. A default compute pool named `default`
   2. A storage account w/ storage account container named `output`
   3. An azure container registry
   4. A user assigned managed identity
      1. This will be used by the batch compute pool to access azure resources.
      2. This identity should be assigned `STORAGE_BLOB_DATA_OWNER` on the azure storage account
      3. This identity should be assigned `ACR_PULL` on the azure container registry
3. Access to the resources via your Entra Id account.
   1. `AZURE_BATCH_ACCOUNT_CONTRIBUTOR` on the azure batch account
   1. `ACR_PUSH` on the azure container registry
   1. `STORAGE_BLOB_DATA_OWNER` on the storage account
4. Using these newly created resources, replace these values in this repository:`<subscriptionId>`, `<resourceGroupName>`,`<batchAccountName>`,`<region>`,`<storageAccountName>`,`<azureContainerRegistryName>`,`<region>`


|      ![Infra](<Batch Diagram.png>)      |
| :-------------------------------------: |
| *Reference Diagram for Azure Resources* |

# POMP Trajectory Mapping

Notebook: [r-pomp-trajectory-mapping.ipynb](./r-pomp-trajectory-mapping.ipynb)

**Goal**: The notebook aims to estimate the parameters of a Verhulst-Pearl population dynamics model using trajectory mapping.  Specifically, by optimizing the negative log-likelihood of the model using the `subplex` algorithm. The focus is on determining the carrying capacity (`K`) and initial population size (`N_0`) that best fit the observed data, using Azure Batch to distribute and parallelize the computational workload. Code in this notebook is based off of [Trajectory Mapping by Aaron A. King](https://kingaa.github.io/pomp/vignettes/getting_started.html#Trajectory_matching), retrofit to leverage azure batch.

**Model**: The model is based on the Verhulst-Pearl (logistic growth) equation, with both stochastic and deterministic components: 
- **Stochastic Process**: The population dynamics are simulated using a stochastic differential equation (`vpstepC`), which introduces random fluctuations around the logistic growth curve. 
- **Deterministic Skeleton**: A deterministic version of the model is also defined using a vector field, which describes the central tendency of the population without stochastic noise. 
- **Objective Function**: The notebook uses `traj_objfun` to create an objective function that quantifies the mismatch between the model's predictions and the observed data, focusing on the parameters `K` and `N_0`.

**Overview of Steps**:
1. **Generating the Objective Function**: The `generate_ofun.R` script creates a POMP object for the Verhulst-Pearl model, incorporating both the stochastic process and deterministic skeleton. An objective function (`ofun`) is generated, which will be used to estimate the parameters by minimizing the negative log-likelihood. This function is saved as `ofun.rds`.
2. **Running Parameter Optimization**: The `run_optimization.R` script loads the saved objective function and uses the `subplex` algorithm to optimize `K` and `N_0`. The optimization is run for different initial values of these parameters, and the results are saved as `.RData` files.
3. **Azure Batch Setup and Execution**: The notebook configures and sets up an Azure Batch environment, uploads the necessary files, and creates a Batch job. Multiple tasks are dispatched, each running the `run_optimization.R` script with different initial values of `K` and `N_0`, allowing the parameter space to be explored in parallel.
4. **Downloading and Analyzing Results**: After the Batch tasks complete, the notebook downloads the `.RData` files containing the optimized parameters and their corresponding negative log-likelihoods. These results are aggregated and analyzed to identify the parameter values that best fit the data.
5. **Visualization**: The notebook creates visualizations of the aggregated simulation outcomes, giving insights to the parameter estimation.

# POMP Iterative Filtering

Notebook: [r-pomp-iterative-filtering.ipynb](./r-pomp-iterative-filtering.ipynb)

**Goal**: The notebook aims to estimate the parameters of a Verhulst-Pearl population dynamics model using the iterated filtering (mif2) algorithm from the r-pomp package, leveraging Azure Batch for distributed computation. The objective is to maximize the likelihood of observed data by refining parameter estimates for the Verhulst-Pearl (logistic growth) model with stochastic components. Code in this notebook based off of [Maximizing liklihood by Iterative Filtering by Aaron A. King](https://kingaa.github.io/pomp/vignettes/getting_started.html#Maximizing_the_likelihood_by_iterated_filtering), retrofit to leverage azure batch.

**Model**: The POMP object in this notebook is generated using a stochastic version of the Verhulst-Pearl model, which simulates population dynamics over time. This model incorporates logistic growth with random noise, defined by a stochastic differential equationin the vpstepC C snippet. Key parameters include the growth rate (r), carrying capacity (K), noise (sigma), and initial population size (N_0).

**Overview of Steps**:
   1. **Parameter Guess Generation**: The notebook begins by generating initial parameter guesses using a Sobol sequence, which explores a wide range of potential values for the model parameters (r, K, sigma, N_0).
   2. **Iterated Filtering (mif2)**: For each parameter guess, the mif2 algorithm refines the parameter estimates by maximizing the likelihood of the observed data, simulating the stochastic dynamics of the Verhulst-Pearl model. Results from these optimizations are saved as .RData files.
   3. **Refinement via Particle Filtering**: After mif2, the notebook uses particle filtering (pfilter) to further refine the estimates and compute log-likelihood values, ensuring the parameters best fit the observed data.
   4. **Azure Batch Execution**: The notebook distributes the computations across Azure Batch, creating tasks that run mif2 and pfilter in parallel for each parameter guess. This enables efficient scaling for larger computational tasks.
   5. **Result Analysis**: Upon completion of the batch tasks, the notebook downloads and analyzes the results, generating trace plots to visualize parameter convergence and pair plots to explore relationships between the parameters.