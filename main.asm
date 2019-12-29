include Irvine32.inc
include macros.inc
BUFFER_SIZE=5000

main  EQU start@0
Cover PROTO
ReadArray PROTO, arrayOffset:Dword, FileNameOffset:Dword
CheckIndex PROTO, X:Byte, Y:Byte, val:Byte
GetValue PROTO, val:Dword, X:Byte, Y:Byte 
CheckAnswer PROTO, X:Byte, Y:Byte, val:Byte
GetBoards PROTO, Diff: Byte ;Difficulty
PrintArray PROTO, val1:Dword
PrintSolvedArray PROTO, val1:Dword
TakeInput PROTO
GetDifficulty PROTO
EditCell PROTO, X:Byte, Y:Byte, val:Byte
IsEditable PROTO
WriteBoardToFile PROTO, val1:Dword, val2:Dword
.data

ChStrs BYTE" *********                   *           *                   "
       BYTE" *                           *           *                   "
       BYTE" *                           *           *      **           "
       BYTE" *                           *           *     **            "
       BYTE" *                           *           *   **              "
       BYTE" *                           *           * **                "
       BYTE" ********* *       * ********* ********* ***       *       * "
       BYTE"         * *       * *       * *       * * **      *       * "
       BYTE"         * *       * *       * *       * *  **     *       * "
       BYTE"         * *       * *       * *       * *   **    *       * "
       BYTE"         * *       * *       * *       * *    **   *       * "
       BYTE"         * *       * *       * *       * *     **  *       * "
       BYTE" ********* ********* ********* ********* *      ** ********* "
outputHandle DWORD 0
bytesWritten DWORD 0
count DWORD 0
xyPosition COORD <0,0>
cellsWritten DWORD ?
attributes0 WORD 10 DUP(0Ch),10 DUP(0Eh),10 DUP(0Ah),10 DUP(0Bh),10 DUP(0Dh),11 DUP(09h)

board Byte 81 DUP(?)    
solvedBoard Byte 81 DUP(?)	
unSolvedBoard Byte 81 DUP(?)	

xCor Byte ?		;X and Y coordinates
yCor Byte ?     
num Byte 1		;input number
difficulty Byte ?	;1 Easy, 2 Medium, 3 Hard

wrongCounter Dword 0	;Game stats counters
correctCounter Dword 0
remainingCellsCount Byte ?

lastGamechoose Byte ?		;Choose whether to go back to the last game


fileName Byte "sudoku-boards/diff_?_?.txt",0		;Data files paths
solvedFileName Byte "sudoku-boards/diff_?_?_solved.txt",0
lastGameFile Byte "sudoku-boards/last_game/board.txt",0
lastGameSolvedFile Byte "sudoku-boards/last_game/board_solved.txt",0
lastGameUnsolvedFile Byte "sudoku-boards/last_game/board_unsolved.txt",0
lastGameDetailsFile Byte "sudoku-boards/last_game/board_details.txt",0

buffer Byte BUFFER_SIZE DUP(?)
fileHandle HANDLE ?

str1 BYTE "Cannot create file",0dh,0ah,0  
newline byte 0Dh,0Ah

;Helper variables for PrintArray procedure
helpCounter Dword ?
helpCounter2 Byte ?

startTime Dword ?
beep byte 07h		;buzzer

.code

;------main-----------

main PROC
	call Cover
	call crlf
	call crlf
	;Ask user to continue last played game
	ASK:
	mWrite "Do you want to continue the last game ?"
	call crlf
	mWrite "Enter Y if Yes or N if No"
	call crlf
	call ReadChar
	call WriteChar
	call crlf
	cmp al,'Y'
	je RunLastGame
	jmp StartGame

	;Loading last game boards from file
	RunLastGame:
	INVOKE GetTickCount
	mov StartTime, eax
		call LoadLastGame
		jmp showBoard

	StartGame:
	call GetDifficulty
	INVOKE GetBoards, difficulty
	INVOKE GetTickCount
	mov StartTime, eax
		jmp ShowBoard

	GamePlay:
		call TakeInput
				
		INVOKE EditCell, xCor, yCor, num 
		call updateRemainingCellsCount
		cmp remainingCellsCount, 0
		je Finish

		call clrscr
		PrintUpdatedBoard:
		cmp eax,1
		jne WrongAnswer
			mov eax,2    ;Set to Green Color
			call SetTextColor
			mWrite "Correct !"
			inc correctCounter
			mov eax,15    ;Set Color Back to white
			call SetTextColor
			call crlf
			jmp ShowBoard
		WrongAnswer:
			mov eax,4    ;Set to Red Color
			call SetTextColor
			mWrite "Wrong Input !  กรกsกร  กรกsกร  กรกsกร "
			inc WrongCounter
			mov eax,15    ;Set Color Back to white
			call SetTextColor
			call crlf

		ShowBoard:
		INVOKE PrintArray, offset Board

		ShowOptions:
		mWrite "Press A to add a new cell"
		call crlf
		mWrite "Press C to reset the current board"
		call crlf
		mWrite "Press S to print the solved board"
		call crlf
		mWrite "Press E to exit and save current board"
		call crlf
		call ReadChar
		call WriteChar
		call crlf
		
		GetChoice:
		cmp ax,1E41h
		je GamePlay
		cmp ax,1245h
		je SaveBoard
		cmp ax,2E43h
		je ResetBoard
		cmp ax,1F53h
		je PrintSolvedBoard

		mWrite "Enter a valid choice!"
		jmp ShowBoard

		;Saving current board if user choses exit
		SaveBoard:
			INVOKE GetTickCount
			SUB eax, startTime

			mWrite <"Time Taken: ">
			call writedec
			call crlf
			mWrite "Number of Remaining cells: "
			call UpdateRemainingCellsCount
			movZX eax,remainingCellsCount
			call writedec

			;Saving boards in data files
			INVOKE WriteBoardToFile, offset board, offset lastGameFile
			INVOKE WriteBoardToFile, offset solvedBoard, offset lastGameSolvedFile

			;Prevent calling dummy file if the game is a continued game
			cmp lastGamechoose, 1
			je SkipLoading

			;Restoring unsolved board from data file
			INVOKE ReadArray, offset board, offset fileName
			INVOKE WriteBoardToFile, offset board, offset lastGameUnsolvedFile

			SkipLoading:
			call crlf
			mWrite " ** Your Board was saved succssfully ! **"
			call crlf
			mWrite " ** Thanks for Playing **"
			call crlf
			call crlf
			exit

		;Rreset current board to initial state
		ResetBoard:
			cmp lastGamechoose,1
			je ResetLastGame

			;call ReadArray with required params to populate board var
			INVOKE ReadArray, offset board, offset filename
			jmp ResetSuccessful

			ResetLastGame:
			;call ReadArray with required params to populate board
			INVOKE ReadArray, offset board, offset lastGameUnsolvedFile

			ResetSuccessful:
				call clrscr
				mWrite "Your Game Was Reset!"
				call crlf
				jmp ShowBoard


		PrintSolvedBoard:
			INVOKE PrintSolvedArray, offset solvedBoard

			INVOKE GetTickCount
			SUB eax, startTime

			call crlf
			mWrite <"Time Taken: ">
			call writedec
			call crlf
			mWrite "Number of Remaining cells: "
			call UpdateRemainingCellsCount
			movzx eax,remainingCellsCount
			call writedec
			call crlf
			call crlf
			mWrite "Number of Incorrect Solutions: "
			mov eax,wrongCounter
			call writedec
			call crlf
			mWrite "Number of Correct Solutions: "
			mov eax,correctCounter
			call writedec
			call crlf
			mWrite " ** Thanks for Playing **"
			call crlf

			exit

	Finish:
		inc correctCounter	;Count last correct submission

		call clrscr
		mWrite "Congratulations You have Finished the board !"
		call crlf
		INVOKE GetTickCount
			SUB eax, startTime

			mWrite <"Time Taken: ">
			call writedec
			call crlf
			mWrite "Number of Incorrect Solutions: "
			mov eax,wrongCounter
			call writedec
			call crlf
			mWrite "Number of Correct Solutions: "
			mov eax,correctCounter
			call writedec
			call crlf

				mWrite " ** Thanks You for Playing **"
			call crlf

	exit
main ENDP


;----------------------Cover-----------------------------
change PROC
    mov edx,0
    push ecx
    mov ecx,61
L2:
    movzx eax,ChStrs[esi]
    call WriteChar
    inc esi
    inc edx
    loop L2
    call Crlf
    pop ecx
        RET
change ENDP

Cover PROC
INVOKE GetStdHandle, STD_OUTPUT_HANDLE ; Get the console ouput handle
    mov outputHandle, eax ; save console handle
    call Clrscr
    mov ecx,13
    mov esi,0
L1:

    call change
      LOOP L1
    mov ecx,13
L2:
    push ecx
    INVOKE WriteConsoleOutputAttribute,
      outputHandle,
      ADDR attributes0,
      61,
      xyPosition,
      ADDR cellsWritten
      inc xyPosition.y
      pop ecx
      loop L2
Cover ENDP

;----------------------Read Array-----------------------------
;Read file number
ReadArray PROC, arrayOffset:Dword, FileNameOffset:Dword
	mov esi, arrayOffset
	mov ebx, FileNameOffset
	mov ecx,34
	
	mov edx,ebx		;Open the file
	call OpenInputFile
	mov fileHandle, eax

	cmp eax, INValID_HANDLE_ValUE	;Check
	jne FileOk	
	mWrite <"Cannot open file", 0dh, 0ah>
	jmp quit

	FileOk :
		mov edx, OFFSET buffer
		mov ecx, BUFFER_SIZE
		call ReadFromFile
		JNC CheckBufferSize	
		mWrite "Error reading file. "	
		call WriteWindowsMsg
		jmp CloseFilee

	CheckBufferSize:
		cmp eax, BUFFER_SIZE	
		jb BufferSizeOk
		mWrite <"Error: Buffer too small for the file", 0dh, 0ah>
		jmp quit

BufferSizeOk :
	mov buffer[eax], 0
	mov ebx, OFFSET buffer
	mov ecx, 97
	mov edx,esi

	StoreContentInTheArray :
		  mov al, [ebx]
		  inc ebx
		  cmp al, 13
		  je SkipBecOfEndl
		  cmp al, 10
		  je SkipBecOfEndl
		  mov [esi], al
		  inc esi
		 SkipBecOfEndl : 
	loop StoreContentInTheArray


	mov esi, edx
	mov ecx, 81
   ConvertFromCharToInt:
		  sub byte ptr[esi],48
	      inc esi 
	loop ConvertFromCharToInt
	
	 mov esi, edx

CloseFilee :
	mov eax, fileHandle
	call CloseFile

	quit :
	ret
ReadArray ENDP

;----------------------CheckIndex----------------------------
CheckIndex PROC, X:Byte, Y:Byte, val:Byte
	
	push eax
	
	mov al, X
	mov xCor, al
	mov al, Y
	mov yCor, al
	mov al, val
	mov num, al
	
	pop eax
	
	cmp xCor,9		;Check x lies between 1 and 9
	ja WRONG
	cmp xCor,1
	jb WRONG


	cmp YCor,9		;Check y lies between 1 and 9
	ja WRONG
	cmp YCor,1
	jb WRONG

	
	cmp num,9		;Check num lies between 1 and 9
	ja WRONG
	cmp num,1
	jb WRONG

	jmp RIGHT

	WRONG:
		mov eax,0
		ret
	RIGHT:
		mov eax,1
		ret
CheckIndex ENDP

;----------------------GetValue------------------------------
GetValue PROC, val:Dword, X:Byte, Y:Byte 
	push ecx
	push edx
	push eax

	mov edx, val
	mov al, X
	mov xCor, al
	mov al, Y
	mov yCor, al

	pop eax

	INVOKE CheckIndex, X, Y, num 
	push ecx
	push edx
	cmp eax, 1
	je Body
		mov eax, -1
		pop edx
		pop ecx
		ret
	Body:
		DEC xCor
		DEC yCor
		mov eax, 9
		movZX ecx, xCor
		Mul ecx
		movZX ecx, yCor
		add eax, ecx
		pop edx
		push edx
		add edx, eax
		mov eax, 0
		mov al, [edx]
		inc xCor
		inc yCor
		pop ecx
		pop edx
		pop edx
		pop ecx
	ret
GetValue ENDP

;----------------------CheckAnswer---------------------------
CheckAnswer PROC, X:Byte, Y:Byte, val:Byte

	push eax
	mov al, X
	mov xCor, al
	mov al, Y
	mov yCor, al
	mov al, val
	mov num, al

	pop eax
	
	INVOKE GetValue, offset solvedBoard, X, Y

	mov bl,num		;moving the value to check to bl
	cmp bl,al		;Comparing the given value with the answer
	je RIGHT
	jmp WRONG

	RIGHT:
	mov eax,1
	ret

	WRONG:
	mov al,beep
	call writechar
	mov eax,0
	
	ret
CheckAnswer ENDP

;----------------------GetBoards----------------------------
GetBoards PROC, Diff: Byte ;Difficulty
	push eax
	mov al, Diff
	mov Difficulty, al

	pop eax

	xor ax,cx

	mov dx,0
	mov bx,4
	div bx

	cmp dx,0	;Setting value to 1 if it's 0
	je ZeroDX
	jmp cont

	ZeroDX:
	mov dx,1

	cont:
	mov al,dl
	add al,'0'
	mov fileName[21],al

	mov al,difficulty
	add al,'0'
	mov fileName[19],al

	mov al,dl
	add al,'0'
	mov solvedFileName[21],al

	mov al,difficulty
	add al,'0'
	mov solvedFileName[19],al

	INVOKE ReadArray, offset board, offset fileName
	INVOKE ReadArray, offset unSolvedBoard, offset fileName
	INVOKE ReadArray, offset solvedBoard, offset solvedFileName

	ret
GetBoards ENDP

;----------------------Print Array----------------------------
PrintArray PROC, val1:Dword
	mov xCor,0
	mov yCor,1

	mov helpCounter,1
	mov helpCounter2,1
	mov edx, val1

	call crlf
	mov al,' '
	call writechar
	call writechar
	call writechar
	call writechar
	mov eax,1
	mov ecx,9

	topNumbers:	
		call writedec
		push eax
		mov al,' '
		call writechar
		call writechar
		
		pop eax
		inc eax
	loop topNumbers
	
	push edx
	mov ecx,81
	L1:
		mov eax,0
		movzx eax,byte ptr [edx]	;eax contains current number
		push eax
		push edx

		mov dx,0
		mov ax,cx     ;DX = CX % 9
 		mov bx,9
		div bx

		cmp dx,0
		jne NoEndl	  ;if DX % 9 = 0 print endl
		inc xCor
		mov yCor,1
		call crlf
		mov al,' ' 
		call writechar
		call writechar
		call writechar
		mov al,'|' 
		call writechar
		
		push ecx
		mov edi,ecx
		mov ecx,9

		dashes:
			mov al,196	 ;horizontal line(-)
			cmp edi,81
			jne process
			push ecx
			mov ecx,3
			mov al,196
		
		horiDashes:
			call writechar
			loop horiDashes
			pop ecx
			jmp endloop

		process:
			cmp edi,54
			je Print
			cmp edi,27
			je Print
			cmp edi,0
			mov al,' '
		
		Print:
			call writechar
			cmp ecx,1
			jne Nobar
			mov al,196
		
		Nobar:
			cmp ecx,1
			jne yarab
			mov al,' '				;leave
		
		yarab:
			call writechar
			cmp ecx,7
			je draw
			cmp ecx,1
			je draw
			cmp ecx,4
			jne skip
		draw:
			mov al,'|'
		skip:
			call writechar
		endloop:
		loop dashes
		pop ecx
	
		call crlf
		mov al,' '
		call writechar
		mov al,helpCounter2
		call writedec
		mov al,' '
		call writechar
		inc helpcounter2
		mov al,'|'
		call writechar

		NoEndl:
			pop edx
			pop eax
			push eax
	cmp eax,0
	je NoRed	;dont Color 0s with red

	INVOKE GetValue, offset unsolvedBoard,xCor,yCor
	cmp eax,0
	jne NoRed

	mov eax,4 ;red color
	call SetTextColor

	NoRed:
		pop eax
		call writeDec
		mov eax,15
		call SetTextColor
		inc yCor
		mov al,' '
		call writechar
		
		mov al, ' '
		cmp helpCounter,3
		jne Print2
		mov al,'|'
		mov helpCounter,0
	Print2:
		call writechar
		inc edx
		inc helpCounter
		
		dec cx
		jne L1  
	call crlf
	mov al,' '
	call writechar
	call writechar
	call writechar
	mov ecx,27
	mov al,196
	BottomDashes:
	call writechar
	loop BottomDashes
	mov al,'|'
	call writechar
	call crlf
	mov al,' '
	call writechar
	pop edx
	ret
PrintArray ENDP

;----------------------PrintSolvedArray----------------------------
PrintSolvedArray PROC, val1:Dword
	mov xCor,0
	mov yCor,1

	mov helpCounter,1
	mov helpCounter2,1
	mov edx, val1

	call crlf
	mov al,' '
	call writechar
	call writechar
	call writechar
	call writechar
	mov eax,1
	mov ecx,9

	topNumbers:	
		call writedec
		push eax
		mov al,' '
		call writechar
		call writechar
		
		pop eax
		inc eax
	loop topNumbers
	
	push edx
	mov ecx,81
	L1:
		mov eax,0
		movzx eax,byte ptr [edx]	;eax contains current number
		push eax
		push edx

		mov dx,0
		mov ax,cx     ;DX = CX % 9
 		mov bx,9
		div bx

		cmp dx,0
		jne NoEndl	  ;if DX % 9 = 0 print endl
		inc xCor
		mov yCor,1
		call crlf
		mov al,' ' 
		call writechar
		call writechar
		call writechar
		mov al,'|' 
		call writechar
		
		push ecx
		mov edi,ecx
		mov ecx,9

		dashes:
			mov al,196	 ;horizontal line(-)
			cmp edi,81
			jne process
			push ecx
			mov ecx,3
			mov al,196
		
		horiDashes:
			call writechar
			loop horiDashes
			pop ecx
			jmp endloop

		process:
			cmp edi,54
			je Print
			cmp edi,27
			je Print
			cmp edi,0
			mov al,' '
		
		Print:
			call writechar
			cmp ecx,1
			jne Nobar
			mov al,196
		
		Nobar:
			cmp ecx,1
			jne yarab
			mov al,' '				;leave
		
		yarab:
			call writechar
			cmp ecx,7
			je draw
			cmp ecx,1
			je draw
			cmp ecx,4
			jne skip
		draw:
			mov al,'|'
		skip:
			call writechar
		endloop:
		loop dashes
		pop ecx
	
		call crlf
		mov al,' '
		call writechar
		mov al,helpCounter2
		call writedec
		mov al,' '
		call writechar
		inc helpcounter2
		mov al,'|'
		call writechar

		NoEndl:
			pop edx
			pop eax
			push eax

	INVOKE GetValue, offset board, xCor, yCor
	cmp eax,0
	jne NoBlue
	mov eax,14
	call SetTextColor
	NoBlue:
		pop eax
		call writeDec
		mov eax,15
		call SetTextColor

		inc yCor
		mov al,' '
		call writechar
		
		mov al, ' '
		cmp helpCounter,3
		jne Print2
		mov al,'|'
		mov helpCounter,0
		Print2:
		call writechar
		inc edx
		inc helpCounter
		
		dec cx
		jne L1  ;because of loop causes too far error

	call crlf
	mov al,' '
	call writechar
	call writechar
	call writechar
	mov ecx,27
	mov al,196
	BottomDashes:
	call writechar
	loop BottomDashes
	mov al,'|'
	call writechar
	call crlf
	mov al,' '
	call writechar
	pop edx
	ret
PrintSolvedArray ENDP


;----------------------TakeInput-----------------------------
TakeInput PROC

	again:
	mWrite "Enter the x coordinate :  " 
	call ReadDec
	mov xCor,al
	mWrite "Enter the y coordinate :  " 
	call ReadDec
	mov yCor,al
	mWrite "Enter the number :  " 
	call ReadDec
	mov num,al

	INVOKE checkindex, xCor, yCor, num
	cmp eax ,1
	je done

	mWrite "There is an error in your input values... Please Re-input them. " 
	call crlf
	jmp again

	done:
	call iseditable
	cmp eax,1
	je Editable
	mWrite "You Cannot edit this place, Please change it."
	call crlf
	jmp again
	Editable:
	mWrite "Edited"
	call crlf
	ret
TakeInput ENDP

;----------------------GetDifficulty-------------------------
GetDifficulty PROC
	again:
	mWrite "Please Enter the difficulty: "
	
	call ReadDec
	cmp al,1	;Checks if the difficulty is 1 or 2 or 3
	je NoError
	cmp al,2
	je NoError
	cmp al,3
	je NoError

	mWrite "Please enter a valid difficulty ( 1 or 2 or 3 ) "
	call crlf
	jmp again	;Re Enter difficulty if it was wrong

	NoError:
	mov difficulty,al	;take the byte from eax which will be 1 or 2 or 3
	ret
GetDifficulty ENDP

;----------------------EditCell------------------------------
EditCell PROC, X:Byte, Y:Byte, val:Byte

	push eax
	mov al, X
	mov xCor, al
	mov al, Y
	mov yCor, al
	mov al, val
	mov num, al

	pop eax
	push edx
	push ecx
	cmp eax, 0
	je Ending
		INVOKE CheckAnswer, X,Y, val
		cmp eax, 0
	je Ending
		DEC xCor
		DEC yCor
		mov eax, 9
		movZX ecx, xCor
		Mul ecx
		movZX ecx, yCor
		add eax, ecx
		mov edx, offset board
		add edx, eax
		mov al, num
		mov [edx], al
		inc xCor
		inc yCor
		DEC remainingCellsCount
		mov eax,1
		pop ecx
		pop edx
		ret
	Ending:
		pop ecx
		pop edx
		mov eax,0
		ret
EditCell ENDP

;----------------------IsEditable----------------------------
IsEditable PROC
	INVOKE GetValue, offset board, xCor, yCor
	cmp eax,0	;Checking value returned from GetValue
	je RIGHT
	jmp WRONG

	RIGHT:
	mov eax,1
	jmp SKIP

	WRONG:
	mov eax,0

	SKIP:
	ret
IsEditable ENDP

;----------------UpdateRemainingCellsCount------------------
UpdateRemainingCellsCount PROC
	push edx
	push ecx
	push eax

	mov remainingCellsCount, 0
	mov edx, offset Board
	mov ecx, 81
	L1:
		mov al, [edx]
		cmp al, 0
		jne skip
			inc remainingCellsCount
		skip:
			inc edx
	Loop L1

	pop eax
	pop ecx
	pop edx
	ret
UpdateRemainingCellsCount ENDP

;----------------------LoadLastGame--------------------------
LoadLastGame PROC
	INVOKE ReadArray, offset board, offset lastGameFile
	INVOKE ReadArray, offset solvedBoard, offset lastGameSolvedFile
	INVOKE ReadArray, offset unSolvedBoard, offset lastGameUnSolvedFile
	mov lastGamechoose,1
	ret
LoadLastGame ENDP

;-------------------WriteBoardToFile-------------------------
WriteBoardToFile PROC, val1:Dword, val2:Dword

	push eax
	mov edx, val1
	mov ebx, val2
	pop eax

	push edx
	 mov ecx,81
	 loo:
		 mov eax,48
		 add [edx],al
		 inc edx
	 LOOP loo

	; Create a new text file and error check.
	 mov edx,ebx	;Move file name offset to edx for CreatOutputFile
	 call CreateOutputFile
	 mov fileHandle,eax

	 cmp eax, INValID_HANDLE_ValUE 
	 jne file_ok	; no: skip
	 mov edx,OFFSET str1
	 call WriteString
	 jmp quit 
	 file_ok:  

   pop edx		;address of the array to be typed
   mov ecx,81	;Length of array

   l5:
	   mov eax,fileHandle
	   push edx		 ;push current character address
	   push ecx		 ;push the loop iterator
	   mov ecx,1
	   call WriteToFile
	   pop ecx

	   ;check if a new line should be printed or not
			mov DX,0
			DEC ecx
			mov AX,CX     ;DX = CX-1 % 9
 			mov BX,9
			DIV BX

			cmp DX,0 	; if not DIV by 9 , then no newline required.
			jne noEndl

			push ecx
			 mov eax,fileHandle
			 mov ecx,lengthof newline
			 mov edx,offset newline
			 call WriteToFile
			pop ecx
	
		noEndl:
	   inc ecx  ;as it was decremented above for calculating modulus
	   pop edx  ;return the address of the read char
	   inc edx  ;staging for writing next char
   loop l5

   quit:
	ret
WriteBoardToFile ENDP

END main
