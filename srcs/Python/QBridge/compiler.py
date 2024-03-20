import pathlib


class FPGAQCCompiler():
    maxQubits = 14
    def __init__(self):
        self.program = []
        self.comments = []
        self.nQubits = None
        self.targetMatrix = None
        self.targetQubit = None
        self.controlQubit = None
        self.GateAsControl = False

    def compile(self, circuit, filepath, filename="FPGAProgram", enableTimer=True):
        self._doNothing()
        if enableTimer:
            self._startTimer()
        
        self._initCircuit(circuit.nQubits)
        for gate in circuit.circuit:
            if gate["type"] == "h":
                self._h(gate["target"])
            elif gate["type"] == "cnot":
                self._cnot(gate["target"], gate["control1"])
            elif gate["type"] == "ccnot":
                self._ccnot(gate["target"], gate["control1"], gate["control2"])
            elif gate["type"] == "x":
                self._x(gate["target"])
            elif gate["type"] == "t":
                self._t(gate["target"])
            else:
                raise Exception("Method not found")
        
        if enableTimer:
            self._stopTimer()
        
        self._serialTransmitStateVector()
        self._halt()
        string = ""
        for i in range(len(self.program)):
            string += f"{self.program[i]} --{self.comments[i]}\n"
        path = pathlib.Path(filepath) / pathlib.Path(f"{filename}.prg")
        with open(path, "w") as f:
            f.write(string)

    def _x(self, target):
        self._applyGate("X", target)
    
    def _h(self, target):
        self._applyGate("H", target)

    def _t(self, target):
        self._applyGate("T", target)

    def _cnot(self, target, control):
        self._applyGate("X", target, control)

    def _ccnot(self, target, control1, control2):
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

    def _initCircuit(self, nQubits):
        self._checkNQubits(nQubits)

        if not self.nQubits == nQubits:
            self._setNQubits(nQubits)

    def _serialTransmitStateVector(self):
        self._setAddressRegister("zero")
        self._serialTransmitNumber()
        self._setAddressRegister("increment")
        self._decrementProgramCounterSerial(n=3)

    def _startTimer(self):
        self._timer("reset")
        self._timer("start")

    def _stopTimer(self):
        self._timer("stop")
    
    def _resumeTimer(self):
        self._timer("start")

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