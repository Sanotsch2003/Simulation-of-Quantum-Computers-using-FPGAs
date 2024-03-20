from QBridge.tools import convertToComplex, getSerialPorts, sendByte, uploadProgram
import threading
import sys
import pathlib
import time
import serial

ROOT_DIR = pathlib.Path(__file__).parent
FPGAProgramsPath = ROOT_DIR / pathlib.Path("FPGAPrograms") # Path to the FPGA programs

roundingThreshold = 0.000000001 # rounding threshold for complex numbers
showEntireStateVector = False # Set to True to only show non-zero elements
DEFAULT_BAUD_RATE = 460800 # Default baud rate for serial communication

helpInfo = "Commands: \n" \
            "exit: exit the program\n" \
            "help: show this help message\n" \
            "send <byte String>: send a byte to the FPGA\n" \
            "upload <file name>: upload a file to the FPGA\n" \
            "getRunTime <HexCode>: get the run time of a program assumung the timer runs with a 100MHz clock frequency\n" \
            "connect <baudRate>: connect to the FPGA with the specified baud rate\n"

terminate = False
port = None

# handles user input to connect to a serial port
def connectToSerialPort(baudRate):
    global port
    port = None
    ports, portnames = getSerialPorts(baudRate=baudRate)
    print("Available ports: ")
    if len(ports) == 0:
        print("No serial ports found, please connect the FPGA and type 'connect <baudrate>' to connect")
    
    else:
        for i in range(len(portnames)):
            print(f"{i}: {portnames[i]}")
    

        while True:
            print("Which port do you want to connect to? Type a number and press enter")
            portNumber = input()
            try:
                port = ports[int(portNumber)]
                portname = portnames[int(portNumber)]
            except Exception as e:
                print(f"Error connecting to port: {e}")
                print("Type 'connect <baudrate>' to connect to try again.")
                port = None

            if port is not None:
                print(f"Connected to {portname} with baud rate {port.baudrate}")

            return 

# waits for data from the serial port, converts it to complex floats, and prints it to the terminal
def waitForSerialData(showEntireStateVector, roundingThreshold):
    global port
    time.sleep(1)

    i = 0
    current_number_bit_string = ""
    last_data_time = time.time()
    transmitting = False

    while True:
        if port == None:
            time.sleep(10)
            continue

        if time.time() - last_data_time > 0.5:
            if transmitting:
                print("End of data")
                transmitting = False
                i = 0

        try: 
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

                                c = convertToComplex(current_number_bit_string, roundingThreshold)
                                if c.real != 0 or showEntireStateVector:
                                    print(i, c)
                                    pass
                                i += 1

                        else:
                            current_number_bit_string += byte[0:7]

        except serial.SerialException as e:
            print(f"Error reading data: {e}")
            print("Disconnected from serial port")
            print("")
            port = None

# handles user interaction with the terminal
def terminalInteraction():
    global port
    global terminate
    
    connectToSerialPort(DEFAULT_BAUD_RATE)

    while True:
        print("")
        userInput = input()

        if userInput == "exit":
            terminate = True
            break

        elif userInput == "help":
            print(helpInfo)

        elif userInput.split(" ")[0] == "send":
            if port == None:
                print("Not connected to serial port")
                continue
            else:
                try:
                    byteInput = userInput.split(" ")[1]
                    byte_value = int(byteInput, 2)
                    byte_data = byte_value.to_bytes(1, byteorder='big')
                    print(f"Sending byte: {byte_data}")
                    sendByte(port = port, byte = byte_data)

                except Exception as e:
                    print(f"Error sending byte: {e}")



        elif userInput.split(" ")[0] == "upload":
            if port == None:
                print("Not connected to FPGA")
                continue
            else:
                try:
                    filename = userInput.split(" ")[1]
                    uploadProgram(port = port, filepath = FPGAProgramsPath, filename = filename)
                except Exception as e:
                    print(f"Error uploading program: {e}")
        
        elif userInput.split(" ")[0] == "getRunTime":
            try:
                intCode = int(userInput.split(" ")[1], 16)
                clkFreq = 100000000
                print(f"Using default clock frequency of {clkFreq/1000000} MHz")
                print(f"Program took {intCode/clkFreq} seconds ({intCode/clkFreq*1000}ms) to run")
            except Exception as e:
                print(f"Error converting hex string to int: {e}")
            

        elif userInput.split(" ")[0] == "connect":
            try:
                baudRate = int(userInput.split(" ")[1])
                connectToSerialPort(baudRate)
            except Exception as e:
                print(f"No valid Baud rate given: {e}")
                print(f"Trying to connect with default baud rate {DEFAULT_BAUD_RATE}")
                connectToSerialPort(DEFAULT_BAUD_RATE)
        
        else:
            print("Unknown command, type 'help' for a list of commands")

# welcome message
print("Welcome to the Quantum Bridge terminal interface")
print("Type 'help' for a list of commands")

# start threads for reading and writing to the serial port
read_thread = threading.Thread(target=waitForSerialData, args=(showEntireStateVector, roundingThreshold))
read_thread.daemon = True
read_thread.start()

write_thread = threading.Thread(target=terminalInteraction, args=())
write_thread.daemon = True
write_thread.start()

# wait for the threads to finish
while not terminate:
    pass

# exit the program
print("Exiting program")
sys.exit()