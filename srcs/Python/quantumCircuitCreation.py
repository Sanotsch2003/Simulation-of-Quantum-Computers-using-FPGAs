from QBridge.quantumCircuit import QuantumCircuit
from QBridge.simulators import runCustomSimulation, runQiskitSimulation
from QBridge.compiler import FPGAQCCompiler
import pathlib

ROOT_DIR = pathlib.Path(__file__).parent
FPGAProgramsPath = ROOT_DIR / pathlib.Path("FPGAPrograms") # Path to the FPGA programs


circuit = QuantumCircuit(nQubits=2) # create a quantum circuit with 2 qubits

# create your circuit here by changing the following code
circuit.h(0)
circuit.cnot(1, 0)


#uncomment the following line to create a random circuit with 10 Gates
#circuit.createRandomCircuit(nGates=10, possibleGates=["h", "x", "t", "cnot", "ccnot"])


circuit.visualise() #visualise the circuit using the quirk online simulator

# run the custom simulator and the qiskit simulator to compare the results
stateVector, time = runCustomSimulation(circuit)
print(stateVector)
print("Custom Circuit Runtime: ", time)

print("\n\n\n")

stateVector, time = runQiskitSimulation(circuit)
print(stateVector)
print("Qiskit Circuit Runtime: ", time)

# compile the circuit to a file that can be uploaded to the FPGA
compiler = FPGAQCCompiler()
compiler.compile(circuit=circuit, filepath=FPGAProgramsPath, filename="TestProgram")