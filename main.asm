INCLUDE Irvine32.inc
INCLUDE macros.inc
BUFFER_SIZE = 9*11

main  EQU start@0
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

; Arrays for loading boards 
answer BYTE BUFFER_SIZE DUP(?) 
question BYTE BUFFER_SIZE DUP(?)
user_answer BYTE BUFFER_SIZE DUP(?)
bool byte BUFFER_SIZE DUP(?)

fileHandle HANDLE ?
fileHandle2 HANDLE ?

; user game info 
wrong byte 0 
correct byte 0 
bool_counter byte 0 
cell byte ?
rows dword 11

; Number of empty cells 
empty_cells byte 0  

; Suduko File Path
easy1 byte "diff_1_1.txt",0
easy1ans byte "diff_1_1_solved.txt",0
easy2 byte "diff_1_2.txt",0
easy2ans byte "diff_1_2_solved.txt",0
easy3 byte "diff_1_3.txt",0
easy3ans byte "diff_1_3_solved.txt",0

normal1 byte "diff_2_1.txt",0
normal1ans byte "diff_2_1_solved.txt",0
normal2 byte "diff_2_2.txt",0
normal2ans byte "diff_2_2_solved.txt",0
normal3 byte "diff_2_3.txt",0
normal3ans byte "diff_2_3_solved.txt",0

hard1 byte "diff_3_1.txt",0  ;12
hard1ans byte "diff_3_1_solved.txt",0 ;19
hard2 byte "diff_3_2.txt",0
hard2ans byte "diff_3_2_solved.txt",0
hard3 byte "diff_3_3.txt",0
hard3ans byte "diff_3_3_solved.txt",0

; used file 
question_temp byte 12 dup(?),0
answer_temp byte 19 dup(?),0

;time calc.
startTime dword ?
endtime dword ?
millisecond dword ?
seconds dword ?
minutes dword ?
hours dword ?
beep byte 07h		;buzzer

.code
main PROC
	call Cover
Start:
	mWrite <"Choose difficulty :", 0dh, 0ah,"1 - Easy", 0dh, 0ah, "2 - Normal", 0dh, 0ah, "3 - Hard",0dh, 0ah, 0>
	mov startTime,eax 
	call Readint
	cmp eax,1
	je easy
	cmp eax,2
	je normal
	cmp eax,3
	je hard

	jmp out_of_range

	easy:
		call Randomize_Level 
		cmp eax,1 
		je Level_One_Easy 
		cmp eax,2 
		je Level_Two_Easy 
		cmp eax,3 
		je Level_Three_Easy 

	normal:
		call Randomize_Level 
		cmp eax,1 
		je Level_One_Normal 
		cmp eax,2 
		je Level_Two_Normal
		cmp eax,3 
		je Level_Three_Normal 

	hard:
		call Randomize_Level 
		cmp eax , 1 
		je Level_One_Hard 
		cmp eax , 2 
		je Level_Two_Hard 
		cmp eax , 3 
		je Level_Three_Hard 

	Level_One_Easy:
		mov edx ,OFFSET  easy1
		call Set_Question_Temp
		mov edx , OFFSET  easy1ans
		call Set_Answer_Temp
		jmp done

	Level_Two_Easy:
		mov edx ,OFFSET  easy2
		call Set_Question_Temp
		mov edx , OFFSET  easy2ans
		call Set_Answer_Temp
		jmp done

	Level_Three_Easy:
		mov edx , OFFSET  easy3
		call Set_Question_Temp
		mov edx , OFFSET  easy3ans
		call Set_Answer_Temp
		jmp done

	Level_One_Normal:
		mov edx , OFFSET  normal1
		call Set_Question_Temp
		mov edx , OFFSET  normal1ans
		call Set_Answer_Temp
		jmp done

	Level_Two_Normal:
		mov edx , OFFSET  normal2
		call Set_Question_Temp
		mov edx , OFFSET  normal2ans
		call Set_Answer_Temp
		jmp done 

	Level_Three_Normal:
		mov edx , OFFSET  normal3
		call Set_Question_Temp
		mov edx , OFFSET  normal3ans
		call Set_Answer_Temp
		jmp done

	Level_One_Hard:
		mov edx , OFFSET  hard1
		call Set_Question_Temp
		mov edx , OFFSET  hard1ans
		call Set_Answer_Temp
		jmp done

	Level_Two_Hard:
		mov edx , OFFSET  hard2
		call Set_Question_Temp
		mov edx , OFFSET  hard2ans
		call Set_Answer_Temp
		jmp done

	Level_Three_Hard:
		mov edx , OFFSET  hard3
		call Set_Question_Temp
		mov edx , OFFSET  hard3ans
		call Set_Answer_Temp

	done:
		call Set_Arrays
		call Options
		jmp quit 

	out_of_range:
		mWrite < "Number Out Of Range ", 0dh, 0ah>
		jmp Start 

	quit:
		call time_calculations
	exit
main ENDP

;----------------------Cover-----------------------------
change PROC
    mov edx,0
    push ecx
    mov ecx,61

	L1:
		movzx eax,ChStrs[esi]
		call WriteChar
		inc esi
		inc edx
		loop L1
		call Crlf
		pop ecx
	ret
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

;----------------------Randomize Level-----------------------------
Randomize_Level PROC
	mov  eax,3    ; random number from 0 to 2 
	call Randomize  ;re-seed generator
	call RandomRange ; set eax to the random number
	inc  eax        ; make the number in range from 1 to 3  
ret
Randomize_Level ENDP

;----------------------Options-----------------------------
Options PROC
	mov edx , offset user_answer
	call DisplayAnswer
	mWrite "Press A to add a new cell"
	call crlf
	mWrite "Press C to reset the current board"
	call crlf
	mWrite "Press S to print the solved board"
	call crlf
	call ReadChar
	call WriteChar
	call crlf

	cmp ax,1E41h
	je Edit
	cmp ax,2E43h
	je Clear
	cmp ax,1F53h
	je Solve

out_of_range2:
	mWrite<" Number Out Of Range ", 0dh, 0ah>
	jmp Options
ret
Options ENDP

;----------------------Edit-----------------------------
Edit PROC
	mWrite<"Enter the x coordinate : ">
	call Readint
	dec eax
	cmp eax,8
	ja out_of_range3
	cmp eax,0
	jb out_of_range3
	mul rows
	mov ebx,eax

	mWrite<"Enter the y coordinate : ">
	call readint
	dec eax
	cmp eax,8
	ja out_of_range3
	cmp eax,0
	jb out_of_range3
	call CheckNumber
	add ebx,eax

	cmp bool[ebx] , 70
	je check

	mov eax,red
	call settextcolor
	mWrite<"The cell is already assigned">
	call White1	
	jmp next

check:
	mWrite<"Enter number  : ">
	call readint
	cmp eax,9
	ja out_of_range3
	cmp eax,0
	jb out_of_range3
	call crlf
	add al , 48 
	mov dl, al

	mov al, answer[ebx]
	cmp dl, al
	je fine
	call Red1
	inc wrong 
	jmp next

fine:
	call Green1
	mov user_answer[ebx] , dl
	mov bool[ebx] , 'M'
	inc correct
	mov al,beep
	call writechar
	mov eax,0
	
next:
	call crlf
	mov al,correct
	cmp al,empty_cells
	je succedd
	jmp options

out_of_range3:
	mwrite< " Number Out Of Range. Please Re-input them.">
	jmp options 
	
succedd:
	mov edx , offset user_answer
	call DisplayAnswer
	mwrite< "Suduko is solved  ">
	call crlf
	mwrite< "Correct Guessing : ">
	mov al , correct
	call writedec
	call crlf 
	mwrite< "Wrong Guessing : ">
	mov al , wrong
	call writedec
	call crlf
ret
Edit ENDP

;----------------------Check Number-----------------------------
CheckNumber PROC
	cmp eax,8
	ja wronno 
	cmp eax,0 
	jb wronno 
	jmp proceed

wronno:
	 mwrite< " Number Out Of Range. Please Re-input them.">
	 jmp options
proceed:
ret
CheckNumber ENDP

;----------------------Clear Number-----------------------------
Clear PROC
	call OpenQue
	mov edx,OFFSET user_answer
	call LoadQuestion
	mov wrong,0 
	mov correct,0 
	call Options
ret
Clear ENDP

;----------------------Solve Number-----------------------------
Solve PROC
	call DisplaySolution
	call WaitMsg
ret
Solve ENDP

;----------------------Set Arrays-----------------------------
Set_Arrays PROC
	call OpenQue
	mov edx,OFFSET question
	call LoadQuestion

	call OpenQue
	mov edx,OFFSET user_answer
	call LoadQuestion	
	call SetBool

	call OpenAnsw
	mov edx,OFFSET answer
	call LoadAnswer
ret
Set_Arrays ENDP

;---------------------- Set Question Top----------------------------
Set_Question_Temp PROC
	mov ecx,12
	mov ebx,OFFSET  question_temp
L1:
	mov al,[edx]
	mov [ebx],al 
	inc edx 
	inc ebx 
	loop L1
ret
Set_Question_Temp ENDP

;---------------------- Set Answer Top----------------------------
Set_Answer_Temp PROC
	mov ecx , 19
	mov ebx,OFFSET  answer_temp
L1:
	mov al,[edx]
	mov [ebx],al 
	inc edx 
	inc ebx 
	loop L1
ret
Set_Answer_Temp ENDP

;---------------------- Print Answer----------------------------
DisplayAnswer PROC
	call crlf
	mov ecx,9
	mov ebx,1
	mWrite<" |">

top_border:
	call Blue1
	mov eax,ebx
	call writedec
	call White1
	mWrite<" ">
	inc ebx
	LOOP top_border
	call crlf
	mWrite<"--">
	mov ecx,9

top_border2:
	mWrite<"--">
	LOOP top_border2
	call crlf
	mov ebp,1
	mov ecx,9

L1:
	call Blue1
	mov eax,ebp
	call writedec
	call White1
	mWrite<"|">
	inc ebp
	mov edi , ecx
	mov ecx , 11

L2:
	mov eax , 0
	movzx esi , bool_counter
	cmp bool[esi] , 70
	je set_zero 
	cmp bool[esi] , 77
	je set_color
	jne con

set_color:
	mov eax , green
	call settextcolor
	jmp con 

set_zero :
	mov eax , yellow
	call settextcolor
	
con:
	inc bool_counter
	cmp ecx , 2 
	jle normal 
	mov al , [edx]
	call writechar
	mov bl , al 
	call White1
	mov al , bl

	cmp ecx, 9
	je aywa
	cmp ecx, 6
	je aywa 
	mwrite< " ">
	jmp normal

aywa: 
	mwrite< "|">

normal:
	inc edx 
	loop L2
	
	mov ecx , edi
	dec ecx 
	call crlf
	cmp ecx, 6
	je aywa2
	cmp ecx, 3
	je aywa2
	jmp la2a

aywa2:
	mwrite<"--------------------",0dh, 0ah>

la2a:
	cmp ecx, 0
	jne L1
	mov bool_counter , 0 

ret
DisplayAnswer ENDP

;---------------------- Print Solution----------------------------
DisplaySolution PROC
	call crlf
	mov ecx,9
	mov ebx,1
	mWrite<" |">

top_border:
	call Blue1
	mov eax,ebx
	call writedec
	call White1
	mWrite<" ">
	inc ebx
	LOOP top_border
	call crlf
	mWrite<"--">
	mov ecx,9

top_border2:
	mWrite<"--">
	LOOP top_border2
	call crlf
	mov edx,OFFSET answer
	mov ecx,9
	mov ebp,1
L1:
	call Blue1
	mov eax,ebp
	call writedec
	call White1
	mWrite<"|">
	inc ebp
	mov edi , ecx
	mov ecx , 11  
L2:
	mov eax , 0 			
	cmp ecx , 2 
	jle normal 
	mov al , [edx]
	call writechar
	cmp ecx, 9
	je aywa
	cmp ecx, 6
	je aywa 
	mwrite< " ">
	jmp normal

aywa: 
	mwrite< "|">

normal:
	inc edx 
	loop L2
	mov ecx , edi 
	call crlf
	cmp ecx, 7
	je aywa2
	cmp ecx, 4
	je aywa2
	jmp la2a

aywa2:
	mwrite<"--------------------",0dh, 0ah>

la2a:
	loop L1	 
	call crlf
ret
DisplaySolution ENDP

;---------------------- Open Question----------------------------
OpenQue PROC
	mov edx,OFFSET question_temp
	call OpenInputFile
ret
OpenQue ENDP

;---------------------- Read Question----------------------------
LoadQuestion PROC
	mov fileHandle,eax	
	mov ecx,buffer_size
	call ReadFromFile
	mov eax,fileHandle
	call CloseFile
ret
LoadQuestion ENDP

;---------------------- Open Answer----------------------------
OpenAnsw PROC
	mov edx,OFFSET answer_temp
	call OpenInputFile
ret
OpenAnsw  ENDP

;---------------------- Read Answer----------------------------
LoadAnswer PROC
	mov fileHandle2,eax	
	mov ecx,buffer_size
	call ReadFromFile
	mov eax,fileHandle2
	call CloseFile
ret
LoadAnswer ENDP

;---------------------- Set Out Color----------------------------
;------White-----(Initial)
White1 PROC
	mov eax , white
	call settextcolor
ret
White1 ENDP

;------Blue-----()
Blue1 PROC
	mov eax,Cyan
	call settextcolor
ret
Blue1 ENDP

;------Red-----(Wrong)
Red1 PROC
	mov eax , red
	call settextcolor
	mWrite<"Wrong number (กรกsกร) (กรกsกร) (กรกsกร)", 0dh, 0ah>		
	mov eax , white
	call settextcolor
ret
Red1 ENDP

;------Green-----(Correct)
Green1 PROC
	mov eax , green
	call settextcolor
	mWrite<"Correct number", 0dh, 0ah>		
	mov eax , white
	call settextcolor
ret
Green1 ENDP

;---------------------- Set Boolean function----------------------------
SetBool PROC
	mov edx , offset bool
	mov ebx , offset question
	mov ecx,9
L1:
	mov edi , ecx
	mov ecx , 11  
	
L2:
	mov al,[ebx]
	sub al,48          ;from ascii to number 
	cmp al,0
	je set_to_false
	jne set_to_true

set_to_false:
	mov esi,'F'
	mov [edx],esi 
	inc empty_cells
	jmp ok

set_to_true:
	mov esi,'T'
	mov [edx],esi
	
ok:
	inc edx 
	inc ebx
	loop L2
	mov ecx , edi 
	loop L1
ret
SetBool ENDP

;---------------------- Time conversion----------------------------
Time_calculations PROC
    mov ebx,startTime
	sub eax,ebx
	mov ebx,1000
	mov edx,0
	div ebx
	mov millisecond,edx

	cmp eax,0
	je done
	mov edx,0
	mov ebx,60
	div ebx
	mov seconds,edx
	cmp eax,0
	je done
	mov edx,0
	div ebx
	mov minutes,edx
	cmp eax,0
	je done
	mov edx,0
	div ebx
	mov hours,edx

done:
	mwrite<' Your Time : '>
	mov eax,hours
	call writedec
	mwrite<':'>
	mov eax,minutes
	call writedec
	mwrite<':'>
	mov eax,seconds
	call writedec
	mwrite<'.'>
	mov eax,millisecond
	call writedec
	call crlf

ret
Time_calculations ENDP
END main