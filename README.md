# JASM
Johnny Simulator Assembler
Compiler that generates .ram files for https://sourceforge.net/projects/johnnysimulator/

## Running and compiling JASM

To compiler jasm just call `make` in the main folder. 
To run it, simply call it with the filename as first argument. It will output a file called `a.ram`

## Programming in JASM
### Labels
Labels are a way to reference a specific position in memory.
You create them like this:
```
label: <>
```
### DB
You use `DB` to define a value in a specific memory location. In order to reference it later, you can precede it by a label.
```
MyImportantVariable: DB 100
```
### Operations
`TAKE` takes a value from memory - Arguments: position (integer) or label
`SAVE` saves a value to memory - Arguments: position (integer) or label
`ADD` adds a memory cell to ACC - Arguments: position (integer) or label
`SUB` subtracts a memory cell from ACC - Arguments: position (integer) or label
`INC` subtracts a memory cell - Arguments: position (integer) or label
`DEC` subtracts a memory cell - Arguments: position (integer) or label
`NULL` sets a memory cell to 0 - Arguments: position (integer) or label
`TST` tests if a memroy cell is 0 and skips the next memory cell if it is - Arguments: position (integer) or label
`JMP` Jump to a memory cell - Arguments: position (integer) or label
`HLT` stop execution - Arguments: no arguments

## Example Programs
Multiply two variables with eachother
```
loop: TAKE result
ADD mul1
SAVE result
DEC mul2
TST mul2 ; mul2 is zero once mul1 was added enough times
JMP loop
HLT
mul1: DB 3
mul2: DB 4
result: DB 0
```

