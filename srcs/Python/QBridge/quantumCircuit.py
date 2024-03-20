import random
import webbrowser

class QuantumCircuit():

    def __init__(self, nQubits):
        self.nQubits = nQubits
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
    
    def visualise(self):
        quirkTranslations = {"h": "H", "cnot": "X", "x": "X", "t": "T", "ccnot": "X", "t": "Z^¼"}
        quirkLink = 'https://algassert.com/quirk#circuit={%22cols%22:['
        doubleQuotes = '%22'
        for i in range(len(self.circuit)):
            gate = self.circuit[i]["type"]
            target = self.circuit[i]["target"]
            control1 = self.circuit[i]["control1"]
            control2 = self.circuit[i]["control2"]
            quirkColumn = "["
            for j in range(self.nQubits):
                if j == target:
                    quirkColumn += doubleQuotes
                    quirkColumn += quirkTranslations[gate]
                    quirkColumn += doubleQuotes

                elif j == control1 or j == control2:
                    quirkColumn += doubleQuotes
                    quirkColumn += '•'
                    quirkColumn += doubleQuotes
                else:
                    quirkColumn += '1'
                if j < self.nQubits - 1:
                    quirkColumn += ","
            quirkColumn += "]"
            quirkLink += quirkColumn
            if i < len(self.circuit)-1:
                quirkLink += ","
        
        quirkLink += "]}"
        webbrowser.open(quirkLink)


        
    
    def createRandomCircuit(self, nGates, possibleGates=["h", "cnot", "x", "t", "ccnot"]):
        qubits = [i for i in range(self.nQubits)]
        for _ in range(nGates):
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
        self.__init__(self.nQubits)