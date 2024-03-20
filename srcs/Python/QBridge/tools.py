import serial
import serial.tools.list_ports
import time
import pathlib
from tqdm import tqdm


def convertToDecimal(binary_string):
    temp = 0
    if binary_string[0] == '1':
        temp = -2

    for i in range(31):
        if binary_string[i+1] == '1':
            temp = temp + 2 ** (-i)

    return temp

def convertToComplex(binary_string):

    real = binary_string[0:32]
    imaginary = binary_string[32:64]

    real = convertToDecimal(real)
    imaginary = convertToDecimal(imaginary)

    c = complex(real, imaginary)
    return c

def getSerialPort(baudRate = 9600):
    ports = serial.tools.list_ports.comports(include_links=True)
    if len(ports) == 0:
        print("No serial ports found")
        print("closing...")
        exit()
    else:
        print("Serial ports found: ")
    for port in ports:
        print(port.device)
        print("---------------------")

    print("Using port: " + ports[0].device)
    portName = ports[0].device
    port = serial.Serial(portName, baudRate, timeout=1)
    return port

def sendByte(port, byte):
    try:
        port.write(byte)
    except serial.SerialException as e:
        print(f"Error sending data: {e}")

def readSerial(port, showEntireStateVector):
    time.sleep(1)

    i = 0
    current_number_bit_string = ""
    last_data_time = time.time()
    transmitting = False

    while True:
        if time.time() - last_data_time > 0.5:
            if transmitting:
                print("End of data")
                transmitting = False
                i = 0

        if port.in_waiting:
            if not transmitting:
                #new line
                print("\n")
                print("Start of data")
                transmitting = True
            data = port.read(port.in_waiting)
            last_data_time = time.time()

            for byte in data:
                    byte = format(byte, '08b')
                    if byte == "00000001": # start byte
                        current_number_bit_string = ""

                    elif byte == "10000001": # end byte
                        if len(current_number_bit_string) == 70:
                            current_number_bit_string = current_number_bit_string[0:64]

                            c = convertToComplex(current_number_bit_string)
                            if (c.real > 0.001 or c.real < -0.001) or showEntireStateVector:
                                print(i, c)
                                pass
                            i += 1

                    else:
                        current_number_bit_string += byte[0:7]

def file_len(filePath):
    with open(filePath) as f:
        for i, l in enumerate(f):
            pass
    return i + 1

def uploadProgram(port, filepath, filename):
    StartEndByte = "11111111"

    if not filename.endswith(".prg"):
        filename = filename + ".prg"
    filePath = pathlib.Path(filepath) / pathlib.Path(filename)
    try:
        sendByte(port = port, byte = int(StartEndByte, 2).to_bytes(1, byteorder='big')) #send start byte
        print(f"Opening file {filename}...")
        with open(filePath, 'r') as file:
            total_lines = file_len(filePath)
            for line in tqdm(file, total=total_lines, desc="Uploading"):
                byte = line.strip().split(" --")[0]
                try:
                    byte_value = int(byte, 2)
                    byte_data = byte_value.to_bytes(1, byteorder='big')
                    sendByte(port = port, byte = byte_data)

                except ValueError as e:
                    print(f"Error converting binary string to byte: {e}")

        sendByte(port = port, byte = int(StartEndByte, 2).to_bytes(1, byteorder='big')) #send end byte
        print("File uploaded")

    except Exception as e:
        print(f"Error uploading program: {e}")