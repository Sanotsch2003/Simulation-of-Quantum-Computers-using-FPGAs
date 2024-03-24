# Quantum Circuit Simulation and FPGA Interaction

## Description

This project is designed for simulating quantum circuits and communicating with an FPGA. It contains two main components:

1. `serialInterface.py`: This script provides a terminal interface for communicating with an FPGA.
2. `QuantumCircuitCreation.py`: This script allows you to create quantum circuits. These circuits can be simulated using a custom Python simulation (useful for understanding the simulation algorithm) or using Qiskit for time efficiency. The circuits can also be compiled to machine code to run on an FPGA.

## Prerequisites

- Python 3.12

## Installation

Before starting the installation, it is recommended to create a new virtual environment for this project. You can use Conda or any other virtual environment manager of your choice.
For example use the following command to create a new conda environment with python 3.12 installed (Conda needs to be installed for this command to work):

```bash
conda create --name myenv python=3.12
```

Once you have your virtual environment set up and activated, you can install the project dependencies with the following command:

```bash
pip install -r requirements.txt
```

In order to be able to access the serial Ports on Linux based systems you might need to run the following command:

```bash
sudo usermod -aG dialout your_username
```
