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
`TAKE` takes a value from memory - Arguments: position (integer) or label<br>
`SAVE` saves a value to memory - Arguments: position (integer) or label<br>
`ADD` adds a memory cell to ACC - Arguments: position (integer) or label<br>
`SUB` subtracts a memory cell from ACC - Arguments: position (integer) or label<br>
`INC` subtracts a memory cell - Arguments: position (integer) or label<br>
`DEC` subtracts a memory cell - Arguments: position (integer) or label<br>
`NULL` sets a memory cell to 0 - Arguments: position (integer) or label<br>
`TST` tests if a memroy cell is 0 and skips the next memory cell if it is - Arguments: position (integer) or label<br>
`JMP` Jump to a memory cell - Arguments: position (integer) or label<br>
`HLT` stop execution - Arguments: no arguments<br>

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
mul1: ;labels can be on their own in a line
DB 3
mul2: DB 4
result: DB 0
```

