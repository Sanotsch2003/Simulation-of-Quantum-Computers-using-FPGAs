00000000 --Do nothing
11000000 --reset timer
11000001 --start timer
00010010 --Set number of qubits to 2
00100000 --Set target qubit to 0
00110001 --Set target matrix to H
01000000 --Calculate state vector
00100001 --Set target qubit to 1
00110011 --Set target matrix to X
11010000 --Set control qubit to 0
01000000 --Calculate state vector
11000010 --stop timer
10000000 --zero address register
01110000 --sends one number with index of addressRegister over serial
10000010 --increment address register
10010011 --Decrement program counter by 3 if value in addressRegister < 3
10110000 --Halt
