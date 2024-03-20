# Quantum Circuit Simulation and FPGA Interaction

## Description

This project is designed for simulating quantum circuits and communicating with an FPGA. It contains two main components:

1. `serialInterface.py`: This script provides a terminal interface for communicating with an FPGA.
2. `QuantumCircuitCreation.py`: This script allows you to create quantum circuits. These circuits can be simulated using a custom Python simulation (useful for understanding the simulation algorithm) or using Qiskit for time efficiency. The circuits can also be compiled to machine code to run on an FPGA.

## Prerequisites

- Python 3.12

## Installation

Before starting the installation, it is recommended to create a new virtual environment for this project. You can use Conda or any other virtual environment manager of your choice.
For example by using the following command:

```bash
conda create --name myenv python=3.12
```

Once you have your virtual environment set up and activated, you can install the project dependencies with the following command:

```bash
pip install -r requirements.txt
```