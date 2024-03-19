from qiskit import QuantumCircuit as QC, transpile
from qiskit_aer import Aer
import numpy as np
import copy
import random
import time


class QuantumCircuit():

    def __init__(self, nQbits):
        self.nQbits = nQbits
        self.circuit = []

    def h(self, target):
        gate = {"type": "h", "target": target, "control1": None, "control2": None}
        self.circuit.append(gate)

    def cnot(self, target, control):
        gate = {"type": "cnot", "target": target, "control1": control, "control2": None}
        self.circuit.append(gate)

    def ccnot(self, target, control1, control2):
        gate = {"type": "ccnot", "target": target, "control1": control1, "control2": control2}
        self.circuit.append(gate)

    def x(self, target):
        gate = {"type": "x", "target": target, "control1": None, "control2": None}
        self.circuit.append(gate)

    def t(self, target):
        gate = {"type": "t", "target": target, "control1": None, "control2": None}
        self.circuit.append(gate)
    
    def loadCircuit(self, circuit):
        pass

    def save(self, filename, createLink=False):
        pass
    
    def createRandomCircuit(self, nGates, possibleGates=["h", "cnot", "x", "t", "ccnot"]):
        qubits = [i for i in range(self.nQbits)]
        for i in range(nGates):
            gate = random.choice(possibleGates)
            random.shuffle(qubits)
            if gate == "h":
                self.h(qubits[0])
            elif gate == "cnot":
                self.cnot(qubits[0], qubits[1])
            elif gate == "x":
                self.x(qubits[0])
            elif gate == "t":
                self.t(qubits[0])
            elif gate == "ccnot":
                self.ccnot(qubits[0], qubits[1], qubits[2])
            else:
                raise Exception("Method not found")

    def reset(self):
        self.__init__(self.nQbits)

class QuantumCircuitSimulator(QuantumCircuit):
    def getStateVector(self):
        pass

    def getProbabilities(self):
        probabilities = np.abs(self.getStateVector())**2
        return probabilities
    
    def printStateVector(self):
        stateVector = self.getStateVector()
        for i in range(len(stateVector)):
            print(f"{i} {stateVector[i]}")
    
class QiskitQCSimulator(QuantumCircuitSimulator):

    def __init__(self, nQbits):
        super().__init__(nQbits)
        self.qc = QC(nQbits)
        self.stateVector = None

    def run(self):
        start = time.time()
        for gate in self.circuit:
            if gate["type"] == "h":
                self.qc.h(gate["target"])
            elif gate["type"] == "cnot":
                self.qc.cx(gate["control1"], gate["target"])
            elif gate["type"] == "ccnot":
                self.qc.ccx(gate["control1"], gate["control2"], gate["target"])
            elif gate["type"] == "x":
                self.qc.x(gate["target"])
            elif gate["type"] == "t":
                self.qc.t(gate["target"])
            else:
                raise Exception("Method not found")

        statevector_simulator = Aer.get_backend('statevector_simulator')
        transpiled_qc = transpile(self.qc, statevector_simulator, optimization_level=0)
        result = statevector_simulator.run(transpiled_qc).result()
        self.stateVector = result.get_statevector()
        end = time.time()
        return end-start

    def getStateVector(self):
        return np.asarray(self.stateVector)
    
class CustomQCSimulator(QuantumCircuitSimulator):
    H = np.array([[complex(1/np.sqrt(2), 0),complex(1/np.sqrt(2), 0)],
                [complex(1/np.sqrt(2), 0),complex(-1/np.sqrt(2), 0)]])

    X = np.array([[complex(0, 0),complex(1, 0)],
                [complex(1, 0),complex(0, 0)]])
    
    T = np.array([[complex(1, 0),complex(0, 0)],
                [complex(0, 0),complex(np.cos(np.pi/4) + 1j*np.sin(np.pi/4), 0)]])

    def __init__(self, nQbits):
        super().__init__(nQbits)
        self.nQbits = nQbits
        self.stateVector = np.array([[complex(1, 0)],[complex(0, 0)]])
        for i in range(1, nQbits):
            self.stateVector = np.kron(self.stateVector, np.array([[complex(1, 0)],[complex(0, 0)]]))
        self.stateVector = self.stateVector.astype(np.complex128)
    
    def getStateVector(self):
        return self.stateVector.flatten()

    def run(self):
        start = time.time()
        for gate in self.circuit:
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
        end = time.time()
        return end-start

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
        #target = self.nQbits - target - 1
        for i in range(0, 2**(self.nQbits-1)):
            index_a, index_b = self._getElementsAandB(i, target)
           
            original_a = copy.deepcopy(self.stateVector[index_a])
            original_b = copy.deepcopy(self.stateVector[index_b])

            new_a = (matrix_2x2[0][0] * original_a + matrix_2x2[0][1] * original_b)[0]
            new_b = (matrix_2x2[1][0] * original_a + matrix_2x2[1][1] * original_b)[0]

            if not control == None:
                if self._is_xth_bit_set(index_a, control) == 1:
                    self.stateVector[index_a][0] = new_a
                    #print("update a")
                else:
                    pass
                    #print("no update a")
                if self._is_xth_bit_set(index_b, control) == 1:
                    self.stateVector[index_b][0] = new_b  
                    #print("update b") 
                else:
                    pass
                    #print("no update b")
            else:  
                #print("update a")
                #print("update b")
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

class FPGAQCCompiler(QuantumCircuit):
    maxQubits = 14
    def __init__(self, nQbits):
        super().__init__(nQbits)
        self.program = []
        self.comments = []
        self.nQubits = None
        self.targetMatrix = None
        self.targetQubit = None
        self.controlQubit = None
        self.GateAsControl = False
        self._doNothing() #first instruction is always do nothing in order to give the processor time to boot up
        self.initCircuit(nQbits)

    def x(self, target):
        super().x(target)
        self._applyGate("X", target)
    
    def h(self, target):
        super().h(target)
        self._applyGate("H", target)

    def t(self, target):
        super().t(target)
        self._applyGate("T", target)

    def cnot(self, target, control):
        super().cnot(target, control)
        self._applyGate("X", target, control)

    def ccnot(self, target, control1, control2):
        super().ccnot(target, control1, control2)

        self._applyGate("H", target, None)
        self._applyGate("X", target, control2)
        for _ in range(3):
            self._applyGate("T", target, None)
        self._applyGate("X", target, control1)
        self._applyGate("T", target, None)
        self._applyGate("X", target, control2)
        for _ in range(3):
            self._applyGate("T", target, None)
        self._applyGate("X", target, control1)
        self._applyGate("T", target, None)
        self._applyGate("T", control2, None)
        self._applyGate("H", target, None)
        self._applyGate("X", control2, control1)
        self._applyGate("T", control1, None)
        for _ in range(3):
            self._applyGate("T", control2, None)
        self._applyGate("X", control2, control1)

    def initCircuit(self, nQubits):
        self._checkNQubits(nQubits)

        if not self.nQubits == nQubits:
            self._setNQubits(nQubits)

    def serialTransmitStateVector(self):
        self._setAddressRegister("zero")
        self._serialTransmitNumber()
        self._setAddressRegister("increment")
        self._decrementProgramCounterSerial(n=3)

    def startTimer(self):
        self._timer("reset")
        self._timer("start")

    def stopTimer(self):
        self._timer("stop")
    
    def resumeTimer(self):
        self._timer("start")

    def compile(self, name="FPGAProgram"):
        self._halt()
        string = ""
        for i in range(len(self.program)):
            string += f"{self.program[i]} --{self.comments[i]}\n"
        with open(f"FPGAPrograms/{name}.prg", "w") as f:
            f.write(string)

    def _doNothing(self):
        instructionCode = "0000"
        parameterCode = "0000"
        self.program.append(instructionCode + parameterCode)
        self.comments.append("Do nothing")

    def _setNQubits(self, n):
        self.nQubits = n
        instructionCode = "0001"
        parameterCode = format(n, '04b')
        self.program.append(instructionCode + parameterCode)
        self.comments.append(f"Set number of qubits to {n}")

    def _setTargetQubit(self, qubit):
        self.targetQubit = qubit
        instructionCode = "0010"
        parameterCode = format(qubit, '04b')
        self.program.append(instructionCode + parameterCode)
        self.comments.append(f"Set target qubit to {qubit}")

    def _setTargetMatrix(self, matrix):
        self.targetMatrix = matrix
        instructionCode = "0011"
        if matrix == "H":
            parameterCode = "0001"
        elif matrix == "T":
            parameterCode = "0010"
        elif matrix == "X":
            parameterCode = "0011"
        self.program.append(instructionCode + parameterCode)
        self.comments.append(f"Set target matrix to {matrix}")
    
    def _calculateStateVector(self):
        instructionCode = "0100"
        parameterCode = "0000"
        self.program.append(instructionCode + parameterCode)
        self.comments.append("Calculate state vector")

    #sends one number with index of addressRegister over serial
    def _serialTransmitNumber(self):
        instructionCode = "0111"
        parameterCode = "0000"
        self.program.append(instructionCode + parameterCode)
        self.comments.append("sends one number with index of addressRegister over serial")

    def _setAddressRegister(self, action="increment"):
        instructionCode = "1000"
        #increments by one
        if action == "increment":
            parameterCode = "0010"
        #decrements by one
        elif action == "decrement":
            parameterCode = "0011"
        #resets to zero
        elif action == "zero":
            parameterCode = "0000"
        #set to 2^nQubits
        else:
            parameterCode = "0001"

        self.program.append(instructionCode + parameterCode)
        self.comments.append(f"{action} address register")

    #decrements the program counter by 3 if value in addressRegister < 2^nQubits-1
    def _decrementProgramCounterSerial(self, n):
        instructionCode = "1001"
        parameterCode = format(n, '04b')
        self.program.append(instructionCode + parameterCode)
        self.comments.append(f"Decrement program counter by {n} if value in addressRegister < {2**self.nQubits-1}")
    
    def _halt(self):
        instructionCode = "1011"
        parameterCode = "0000"
        self.program.append(instructionCode + parameterCode)
        self.comments.append("Halt")
    
    def _timer(self, action="reset"):
        instructionCode = "1100"
        #resets the timer
        if action == "reset":
            parameterCode = "0000"
        #starts the timer
        elif action == "start":
            parameterCode = "0001"
        #stops the timer
        else:
            parameterCode = "0010"
        self.program.append(instructionCode + parameterCode)
        self.comments.append(f"{action} timer")
    
    def _setControlQubit(self, qubit):
        self.controlQubit = qubit
        self.GateAsControl = True
        instructionCode = "1101"
        parameterCode = format(qubit, '04b')
        self.program.append(instructionCode + parameterCode)
        self.comments.append(f"Set control qubit to {qubit}")
    
    def _deactivateControlQubit(self):
        self.GateAsControl = False
        instructionCode = "1110"
        parameterCode = "0000"
        self.program.append(instructionCode + parameterCode)
        self.comments.append("Deactivate control qubit")

    def _checkQubitInput(self, qubit):
        if not isinstance(qubit, int):
            raise TypeError("qubit must be an integer")
        elif self.nQubits == None:
            raise ValueError("nQubits must be initialized")
        elif qubit < 0 or qubit >= self.nQubits:
            raise ValueError("qubit must be between 0 and " + str(self.nQubits-1))

    def _checkNQubits(self, n):
        if not isinstance(n, int):
            raise TypeError("n must be an integer")
        elif n < 0 or n > self.maxQubits:
            raise ValueError("n must be between 1 and " + str(self.maxQubits))

    def _checkGateInput(self, gate):
        if not isinstance(gate, str):
            raise TypeError("gate must be a string")
        elif not gate in ["H", "T", "X"]:
            raise ValueError("gate must be H, T, or X")
    
    def _applyGate(self, gate="H", targetQubit=0, controlQubit=None):
        self._checkGateInput(gate)
        self._checkQubitInput(targetQubit)
        if controlQubit != None:
            self._checkQubitInput(controlQubit)
            if controlQubit == targetQubit:
                raise ValueError("Control qubit cannot be the same as target qubit")

        if not targetQubit == self.targetQubit:
            
            self._setTargetQubit(targetQubit)
        
        if not self.targetMatrix == gate:
            
            self._setTargetMatrix(gate)

        if controlQubit != None:
            if not controlQubit == self.controlQubit or not self.GateAsControl:
                self._setControlQubit(controlQubit)
        else:
            if self.GateAsControl:
                self._deactivateControlQubit()

        self._calculateStateVector()

