00000000 --Do nothing
00010011 --Set number of qubits to 3
11000000 --reset timer
11000001 --start timer
00100000 --Set target qubit to 0
00110001 --Set target matrix to H
01000000 --Calculate state vector
00100001 --Set target qubit to 1
01000000 --Calculate state vector
00100010 --Set target qubit to 2
01000000 --Calculate state vector
00100000 --Set target qubit to 0
00110011 --Set target matrix to X
01000000 --Calculate state vector
00100010 --Set target qubit to 2
00110001 --Set target matrix to H
01000000 --Calculate state vector
01000000 --Calculate state vector
00110011 --Set target matrix to X
11010001 --Set control qubit to 1
01000000 --Calculate state vector
00110010 --Set target matrix to T
11100000 --Deactivate control qubit
01000000 --Calculate state vector
01000000 --Calculate state vector
01000000 --Calculate state vector
00110011 --Set target matrix to X
11010000 --Set control qubit to 0
01000000 --Calculate state vector
00110010 --Set target matrix to T
11100000 --Deactivate control qubit
01000000 --Calculate state vector
00110011 --Set target matrix to X
11010001 --Set control qubit to 1
01000000 --Calculate state vector
00110010 --Set target matrix to T
11100000 --Deactivate control qubit
01000000 --Calculate state vector
01000000 --Calculate state vector
01000000 --Calculate state vector
00110011 --Set target matrix to X
11010000 --Set control qubit to 0
01000000 --Calculate state vector
00110010 --Set target matrix to T
11100000 --Deactivate control qubit
01000000 --Calculate state vector
00100001 --Set target qubit to 1
01000000 --Calculate state vector
00100010 --Set target qubit to 2
00110001 --Set target matrix to H
01000000 --Calculate state vector
00100001 --Set target qubit to 1
00110011 --Set target matrix to X
11010000 --Set control qubit to 0
01000000 --Calculate state vector
00100000 --Set target qubit to 0
00110010 --Set target matrix to T
11100000 --Deactivate control qubit
01000000 --Calculate state vector
00100001 --Set target qubit to 1
01000000 --Calculate state vector
01000000 --Calculate state vector
01000000 --Calculate state vector
00110011 --Set target matrix to X
11010000 --Set control qubit to 0
01000000 --Calculate state vector
00100000 --Set target qubit to 0
11100000 --Deactivate control qubit
01000000 --Calculate state vector
00100010 --Set target qubit to 2
00110001 --Set target matrix to H
01000000 --Calculate state vector
00100000 --Set target qubit to 0
01000000 --Calculate state vector
00100001 --Set target qubit to 1
01000000 --Calculate state vector
00100010 --Set target qubit to 2
01000000 --Calculate state vector
00100000 --Set target qubit to 0
00110011 --Set target matrix to X
01000000 --Calculate state vector
00100001 --Set target qubit to 1
01000000 --Calculate state vector
00100010 --Set target qubit to 2
01000000 --Calculate state vector
00110001 --Set target matrix to H
01000000 --Calculate state vector
01000000 --Calculate state vector
00110011 --Set target matrix to X
11010001 --Set control qubit to 1
01000000 --Calculate state vector
00110010 --Set target matrix to T
11100000 --Deactivate control qubit
01000000 --Calculate state vector
01000000 --Calculate state vector
01000000 --Calculate state vector
00110011 --Set target matrix to X
11010000 --Set control qubit to 0
01000000 --Calculate state vector
00110010 --Set target matrix to T
11100000 --Deactivate control qubit
01000000 --Calculate state vector
00110011 --Set target matrix to X
11010001 --Set control qubit to 1
01000000 --Calculate state vector
00110010 --Set target matrix to T
11100000 --Deactivate control qubit
01000000 --Calculate state vector
01000000 --Calculate state vector
01000000 --Calculate state vector
00110011 --Set target matrix to X
11010000 --Set control qubit to 0
01000000 --Calculate state vector
00110010 --Set target matrix to T
11100000 --Deactivate control qubit
01000000 --Calculate state vector
00100001 --Set target qubit to 1
01000000 --Calculate state vector
00100010 --Set target qubit to 2
00110001 --Set target matrix to H
01000000 --Calculate state vector
00100001 --Set target qubit to 1
00110011 --Set target matrix to X
11010000 --Set control qubit to 0
01000000 --Calculate state vector
00100000 --Set target qubit to 0
00110010 --Set target matrix to T
11100000 --Deactivate control qubit
01000000 --Calculate state vector
00100001 --Set target qubit to 1
01000000 --Calculate state vector
01000000 --Calculate state vector
01000000 --Calculate state vector
00110011 --Set target matrix to X
11010000 --Set control qubit to 0
01000000 --Calculate state vector
00100010 --Set target qubit to 2
00110001 --Set target matrix to H
11100000 --Deactivate control qubit
01000000 --Calculate state vector
00100000 --Set target qubit to 0
00110011 --Set target matrix to X
01000000 --Calculate state vector
00100001 --Set target qubit to 1
01000000 --Calculate state vector
00100010 --Set target qubit to 2
01000000 --Calculate state vector
00100000 --Set target qubit to 0
00110001 --Set target matrix to H
01000000 --Calculate state vector
00100001 --Set target qubit to 1
01000000 --Calculate state vector
00100010 --Set target qubit to 2
01000000 --Calculate state vector
11000010 --stop timer
10000000 --zero address register
01110000 --sends one number with index of addressRegister over serial
10000010 --increment address register
10010011 --Decrement program counter by 3 if value in addressRegister < 7
10110000 --Halt
