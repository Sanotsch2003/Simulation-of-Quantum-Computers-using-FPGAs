from qiskit import QuantumCircuit as QC, transpile
from qiskit_aer import Aer
import numpy as np
import copy
import time

def runQiskitSimulation(circuit):
    nQubits = circuit.nQubits
    qCircuit = QC(nQubits)
    for gate in circuit.circuit:
        if gate["type"] == "h":
            qCircuit.h(gate["target"])
        elif gate["type"] == "cnot":
            qCircuit.cx(gate["control1"], gate["target"])
        elif gate["type"] == "ccnot":
            qCircuit.ccx(gate["control1"], gate["control2"], gate["target"])
        elif gate["type"] == "x":
            qCircuit.x(gate["target"])
        elif gate["type"] == "t":
            qCircuit.t(gate["target"])
        else:
            raise Exception("Method not found")
        
    startTime = time.time()
    statevector_simulator = Aer.get_backend('statevector_simulator')
    transpiled_qc = transpile(qCircuit, statevector_simulator, optimization_level=0)
    result = statevector_simulator.run(transpiled_qc).result()
    stateVector = np.asarray(result.get_statevector())
    endTime = time.time()

    stateVectorString = ""
    for i in range(len(stateVector)):
        stateVectorString += f"{i}: {stateVector[i]}\n"
    return stateVectorString, endTime-startTime

def runCustomSimulation(circuit):
    simulator = CustomQCSimulator(circuit.nQubits)
    startTime = time.time()
    stateVector =  simulator.run(circuit.circuit)
    endTime = time.time()
    return stateVector, endTime-startTime

class CustomQCSimulator():
    H = np.array([[complex(1/np.sqrt(2), 0),complex(1/np.sqrt(2), 0)],
                [complex(1/np.sqrt(2), 0),complex(-1/np.sqrt(2), 0)]])

    X = np.array([[complex(0, 0),complex(1, 0)],
                [complex(1, 0),complex(0, 0)]])
    
    T = np.array([[complex(1, 0),complex(0, 0)],
                [complex(0, 0),complex(np.cos(np.pi/4) + 1j*np.sin(np.pi/4), 0)]])

    def __init__(self, nQbits):
        self.nQbits = nQbits
        self.stateVector = np.array([[complex(1, 0)],[complex(0, 0)]])
        for i in range(1, nQbits):
            self.stateVector = np.kron(self.stateVector, np.array([[complex(1, 0)],[complex(0, 0)]]))
        self.stateVector = self.stateVector.astype(np.complex128)
    
    def getStateVector(self):
        stateVectorString = ""
        self.stateVector = self.stateVector.flatten()
        for i in range(len(self.stateVector)):
            stateVectorString += f"{i}: {self.stateVector[i]}\n"
        return stateVectorString

    def run(self, circuit):
        for gate in circuit:
            if gate["type"] == "h":
                self._operation(self.H, gate["target"], control=None)
            elif gate["type"] == "cnot":
                self._operation(self.X, gate["target"], control=gate["control1"])
            elif gate["type"] == "ccnot":
                self._ccnot(gate["target"], gate["control1"], gate["control2"])
            elif gate["type"] == "x":
                self._operation(self.X, gate["target"], control=None)
            elif gate["type"] == "t":
                self._operation(self.T, gate["target"], control=None)
            else:
                raise Exception("Method not found")
        stateVector = self.getStateVector()
        return stateVector

    def _ccnot(self, target, control1, control2):
        self._operation(self.H, target, control=None)
        self._operation(self.X, target, control=control2)
        for _ in range(3):
            self._operation(self.T, target, control=None)
        self._operation(self.X, target, control=control1)
        self._operation(self.T, target, control=None)
        self._operation(self.X, target, control=control2)
        for _ in range(3):
            self._operation(self.T, target, control=None)
        self._operation(self.X, target, control=control1)
        self._operation(self.T, target, control=None)
        self._operation(self.T, control2, control=None)
        self._operation(self.H, target, control=None)
        self._operation(self.X, target=control2, control=control1)
        self._operation(self.T, control1, control=None)
        for _ in range(3):
            self._operation(self.T, control2, control=None)
        self._operation(self.X, target=control2, control=control1)

    def _operation(self, matrix_2x2, target, control=None):
        for i in range(0, 2**(self.nQbits-1)):
            index_a, index_b = self._getElementsAandB(i, target)
           
            original_a = copy.deepcopy(self.stateVector[index_a])
            original_b = copy.deepcopy(self.stateVector[index_b])

            new_a = (matrix_2x2[0][0] * original_a + matrix_2x2[0][1] * original_b)[0]
            new_b = (matrix_2x2[1][0] * original_a + matrix_2x2[1][1] * original_b)[0]

            if not control == None:
                if self._is_xth_bit_set(index_a, control) == 1:
                    self.stateVector[index_a][0] = new_a
                if self._is_xth_bit_set(index_b, control) == 1:
                    self.stateVector[index_b][0] = new_b  
            else:  
                self.stateVector[index_a][0] = new_a
                self.stateVector[index_b][0] = new_b

    def _getElementsAandB(self, n, target):
        mask = (1 << target) - 1
        not_mask = ~mask

        nAndMask = n & mask
        nAndNotMask = n & not_mask
        nAndNotMask <<= 1
        result_0 = nAndMask | nAndNotMask

        x = (1 << target)
        result_1 = result_0 | x

        return result_0, result_1
    
    def _is_xth_bit_set(self, a, x):
        return (a >> x) & 1
