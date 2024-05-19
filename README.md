# Project Name

## Description
This repository models an energy arbitrage problem using Julia JuMP. It leverages state-of-the-art GPU technology to efficiently solve large optimization problems.

This project uses a first order solver to solve the problem. In order to install SCS, use `Pkg.add("SCS")`. However, if you wish to use SCS on a GPU, use the CUDA version of it. Unfortunately, at the moment only CUDA is supported.

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Installation
To install and set up this project, follow these steps:
1. Clone the repository: `git clone https://github.com/your-username/your-repository.git`
2. Install Julia: [Download Julia](https://julialang.org/downloads/)
3. Install the required packages by running the following command in the Julia REPL:
    ```julia
    using Pkg
    Pkg.activate(".")
    Pkg.instantiate()
    ```
4. Install CUDA: [Download CUDA](https://developer.nvidia.com/cuda-downloads)
5. Run the project using the following command:
    ```julia
    julia --project=. main.jl
    ```

## Usage
To use this project, follow these steps:
1. Open a terminal and navigate to the project directory.
2. Run the project using the following command:
    ```julia
    julia --project=. main.jl
    ```
3. Follow the on-screen instructions to input the required parameters and solve the energy arbitrage problem.

## Contributing
Contributions to this project are welcome. To contribute, please follow these guidelines:
1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them.
4. Push your changes to your forked repository.
5. Submit a pull request to the main repository.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
