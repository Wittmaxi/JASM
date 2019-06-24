{
	Jonny simulator ASseMbler.
	assembler compiler for the Johnny Simulator https://sourceforge.net/projects/johnnysimulator/files/latest/download written by Peter Dauscher!

	Copyright Maximilian Wittmer 2019
	Released under the GNU GPL license - Compiled by FPC
}

program JASM;

uses sysutils;

type StrArr = Record 
	arr: string;
	ind: integer;
end;

type IntArr = Record
	arr: array of integer;
	ind: integer;
end;

type LabelArr = Record
	name: array of string;
	pos: array of integer;
	ind: Integer;
end;

type FixupArr = Record
	name: array of string;
	fixupPos: array of integer;
	loc: array of integer;
	ind: integer;
end;

{	Variables 	}

var 
	charBuf: char;
	fileHandle: text;
	codeValid: boolean = true;
	lineNumber: integer = 0;	
	outputCode: StrArr;
	outLines: integer = 0;
	labels: LabelArr;	
	fixup: FixupArr;

{	Array Utils	}


procedure InitArrays ();
begin
	outputCode.ind := 1;
	labels.ind := 1;
	fixup.ind := 1;
	setLength (outputCode.arr, 100);
	setLength (labels.name, 100);
	setLength (labels.pos, 100);
	setLength (fixup.name, 100);
	setLength (fixup.fixupPos, 100);
	setLength (fixup.loc, 100);
end;

procedure AppendStrArr (var appendTo: StrArr; val: char);
begin
	if (Length (appendTo.arr) >= appendTo.ind) then { gotta allocate more }
		SetLength (appendTo.arr, High(appendTo.arr) + 100);
	appendTo.arr[appendTo.ind] := val;
	appendTo.ind += 1;
end;

procedure AppendIntArr (var appendTo: IntArr; val: integer);
begin
	if (Length (appendTo.arr) >= appendTo.ind) then { gotta allocate more }
		SetLength (appendTo.arr, High(appendTo.arr) + 100);
	appendTo.arr[appendTo.ind] := val;
	appendTo.ind += 1;
end;

procedure AppendFixupArr (name_: string; position_, loc_: integer);
begin
	if (Length (fixup.name) >= fixup.ind) then { gotta allocate more }
	begin
		SetLength (fixup.name, High(fixup.name) + 100);
		SetLength (fixup.fixupPos, High(fixup.fixupPos) + 100);
		SetLength (fixup.loc, High(fixup.loc) + 100);
	end;
	fixup.name[fixup.ind] := name_;
	fixup.fixupPos[fixup.ind] := position_;
	fixup.loc[fixup.ind] := loc_;
	fixup.ind += 1;
end;


procedure AppendToLabelArr (name_: string; position_: integer);
begin
	if (Length (labels.name) >= labels.ind) then { gotta allocate more }
	begin
		SetLength (labels.name, High(labels.name) + 100);
		SetLength (labels.pos, High(labels.pos) + 100);
	end;
	labels.name[labels.ind] := name_;
	labels.pos[labels.ind] := position_;
	labels.ind += 1;
end;


{	Parser Utils	}

function PeekNext (): byte;
begin
	if (charBuf = Chr(0)) AND (NOT EOF (fileHandle)) then
		read (fileHandle, charBuf);
	if Ord (charBuf) = 13 then { On some systems, lines are terminated by two symbols. Catch the first one }
	begin
		charBuf := Chr (0);
		PeekNext := PeekNext();
	end else
	PeekNext := Ord(charBuf);
end;

function GetNext (): byte;
begin
	GetNext := PeekNext;
	charBuf := Chr(0);
end;

function IsBetween (a, b, toTest: byte): boolean;
begin
	IsBetween := (toTest <= b) AND (toTest >= a); 
end;

function IsNumber (t: byte): boolean;
begin
	IsNumber := IsBetween ($30, $39, t);
end;

function IsLetter (t: byte): boolean;
begin
	IsLetter := IsBetween ($41, $5A, t) OR IsBetween ($61, $7A, t);
end;

function IsAlpha (t: byte): boolean;
begin
	IsAlpha := IsLetter (t) OR IsNumber (t);
end;

function ReadWhileAlpha (): string;
var tmp: string = '';
begin
	while IsAlpha (PeekNext) do
		tmp += chr (GetNext);	
	ReadWhileAlpha := tmp;
end;

function ReadWhileNumber(): string;
var tmp: string = '';
begin
	while IsNumber (PeekNext) do
		tmp += chr (GetNext);
	ReadWhileNumber := tmp;
end;

procedure FlushToNewLine ();
begin
	while (NOT EOF (fileHandle)) AND (GetNext <> 10) do
		; { consume the current byte until we hit a new line }
end;

procedure SkipSpaces ();
begin
	while (PeekNext = $20) OR (PeekNext = $9) do
		GetNext;
end;

{	Error Handling		}

procedure ThrowError (err: string);
begin
	writeln ('[JASM] ERROR ON LINE ' + IntToStr(lineNumber + 1) + ': ' + err);
	codeValid := false;
end;

procedure ExpectCommentOrNL ();
begin
	SkipSpaces;
	if PeekNext = $3B then { next char is ; }
		FlushToNewLine
	else if (PeekNext <> $A) AND (PeekNext <> $0) then
		ThrowError ('Expected comment, new line or EOF, got "' + Chr(PeekNext) + '"'); 
end;

{	File utils	}

procedure NewLine ();
begin
	outLines := outLines + 1;
	AppendStrArr (outputCode, Chr($A));
end;


{	Compilation Utils	}


procedure HandleString();
begin
	while PeekNext <> $27 do
	begin
		AppendStrArr (outputCode, Chr(GetNext));
		NewLine();
	end;
	GetNext;
end;

procedure HandleDB();
var 
	arg: string;
	counter: integer;
begin
	GetNext; 
	if PeekNext = $27 then { next byte is a ' }
		HandleString()
	else
	begin
		arg := ReadWhileNumber;
		for counter := 1 to length (arg) do
			AppendStrArr (outputCode, arg[counter]); 
	end;
	NewLine();
	{ If the rest of the line is invalid, it will be caught in the compile loop }
end;

procedure AppendOPCOnly (opc: byte); { bigger opcodes need two digits }
begin
	if (opc > 9) then
	begin
		AppendStrArr (outputCode, Chr ((opc div 10) + $30));
		opc := opc mod 10;
	end;
	AppendStrArr (outputCode, Chr (opc + $30));
end;

procedure AppendOPC(opc: byte);
begin
	AppendOPCOnly (opc);
	AppendStrArr (outputCode, '0');
	AppendStrArr (outputCode, '0');
	AppendStrArr (outputCode, '0');
	NewLine;
end;

procedure AppendOPCWithArg(opc: byte);
var
	arg: string;
	counter: integer;
begin
	SkipSpaces;	
	arg := ReadWhileNumber;
	AppendOPCOnly (opc);
	if (length (arg) > 3) then
		ThrowError ('Number too big for Johnny')
	else if (length (arg) = 0) then
	begin { it must be a label, since there was no number }
		if not IsAlpha (PeekNext) then
		begin 
			ThrowError ('Expected label or Value');
			exit;
		end;
		AppendFixupArr (ReadWhileAlpha, outputCode.ind, lineNumber);
		outputCode.ind := outputCode.ind + 3; { reserve space for three values }		
		NewLine;
	end else begin
		for counter := 0 to (2 - length (arg)) do 
			AppendStrArr (outputCode, '0');
		for counter := 1 to length (arg) do
			AppendStrArr (outputCode, arg[counter]);
		NewLine;
	end;
end;

function HandleOPC(ident: string): boolean;
begin
	if ident = 'TAKE' then
		AppendOPCWithArg (1)
	else if ident = 'ADD' then
		AppendOPCWithArg (2)
	else if ident = 'SUB' then
		AppendOPCWithArg(3)
	else if ident = 'SAVE' then
		AppendOPCWithArg (4)
	else if ident = 'JMP' then
		AppendOPCWithArg(5)
	else if ident = 'TST' then
		AppendOPCWithArg(6)
	else if ident = 'INC' then
		AppendOPCWithArg (7)
	else if ident = 'DEC' then
		AppendOPCWithArg (8)
	else if ident = 'NULL' then
		AppendOPCWithArg (9)
	else if ident = 'HLT' then
		AppendOPC (10)
	else
	begin
		HandleOPC := false;
		exit;
	end;
	HandleOPC := true;
end;

procedure CompileLine(); Forward;
procedure HandleLabel(name: string);
var 
	counter: integer;
	success: boolean = true;
begin
	if (name = '') then
		exit;
	for counter := 0 to labels.ind do
	begin
		if labels.name[counter] = name then
		begin
			success := false;
			break;
		end;
	end;
	if not success then
	begin
		ThrowError ('label ' + name + ' already exists.');
		exit;
	end;
	AppendToLabelArr (name, outLines);
	SkipSpaces;
	if not (PeekNext = $3A) then
		ThrowError ('Expected :')
	else
		GetNext;
	CompileLine();
end;

{	infrastructure		}

procedure FixupLabels(); 
var
	i, j, lPos: integer;
begin
	if labels.ind <= 1 then
		exit;
	for i := 1 to fixup.ind -1 do
	begin
		lPos := -1;
		for j := 1 to labels.ind -1 do
		begin
			if labels.name [j] = fixup.name [i] then
			begin
				lPos := labels.pos[j];
				break;
			end;		
		end;
		if lPos = -1 then
			writeln ('Label ' + fixup.name[i] + ' on line ' + IntToStr(fixup.loc[i]) + ' not found!')
		else begin
			outputCode.arr[fixup.fixupPos[i]] := Chr(lPos div 100 + $30);
			lPos := lPos mod 100;
			outputCode.arr[fixup.fixupPos[i] + 1] := Chr(lPos div 10 + $30);
			lPos := lPos mod 10;
			outputCode.arr[fixup.fixupPos[i] + 2] := Chr(lPos + $30);
		end;
	end;
end;

procedure CompileLine(); 
var ident: string;
begin
	SkipSpaces;
	ident := ReadWhileAlpha;
	if ident = 'DB' then
		handleDB
	else if NOT handleOPC (ident) then
		handleLabel (ident);
end;

procedure CompileLoop ();
begin
	Assign (fileHandle, 'in.jasm');
	Reset (fileHandle);
	while NOT EOF (fileHandle) do
	begin
		CompileLine;
		ExpectCommentOrNL;
		lineNumber := lineNumber + 1;
		GetNext;
	end;
end;

var 
	outFile: textfile;
	counter: integer;
begin
	InitArrays;
	CompileLoop;
	if codeValid = true then
	begin
		FixupLabels;
		Assign (outFile, 'a.ram');
		Rewrite (outFile);
		for counter := 1 to outputCode.ind - 1 do
			write (outFile, outputCode.arr [counter]);
		for counter := outLines to 1000 do
			writeln (outFile, '0');
		Close (outFile);
	end;
end.