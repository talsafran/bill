; --------------------------------------------------------------------------
; 	BILL'S LAST JOB
; --------------------------------------------------------------------------
;	Written by Tal Safran
;	  E-Mail: safran \\AT\\ nyu //D0T// edu
;   	  NYU ID: N19420196

; 	V22.0201 - Computer Systems Organization
; 	Fall 2008, New York University
; 	Professor Nathan Hull
; --------------------------------------------------------------------------
	JMP	MAIN
; Game speed! Very important!
SPEED	DB	50		; Any value between 1-99
D_LOOP	EQU	1400		; Delay loop (Higher value = slower)
; DOS Settings
DOSC_C	DB	?		; Original column of DOS cursor
; Sound Settings
SOUND	DB	0		; Sound? (0 - OFF, else - ON)
; For saved games
PLAYER	DB	9 DUP (' ')	; Maximum 8 chars. Spaces will be trimmed later
;				  Last space used as EOF
FNAME	DB	15 DUP (0)	; Complete file name for saved
FHANDLE	DW	?		; File handle for writing/reading files
; File data: <Current level>, <Sound ON/OFF), <Delay>, <Attempts for levs 1-9)
FDATA	DB	1, 0FFH, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0	; 12 bytes total
; Menu settings
MENU_COL EQU	48		; Column for menu cursor
MENU_ROW DB	12		; Row variable for menu cursor
MENU_INST EQU	12		; Row location for INSTRUCTIONS
MENU_STRT EQU	14		; Row location for START GAME
MENU_LOAD EQU	16		; Row location for LOAD GAME
MENU_EXIT EQU	18		; Row location for EXIT
; Definition of Colors
C_DOS	EQU	07H		; Grey on black
C_WALL	EQU	44H		; Wall color (Red)
C_BUG	EQU	02H		; BUG color (Green on black)
C_BRN	EQU	0CH		; Brain color (Light red on black)
C_STATUS EQU	4FH		; Status bar (White on red)
C_RNG	EQU	4EH		; Range (yellow on red)
C_INTRO1 EQU	0FH		; White on black
C_INTRO2 EQU	0EH		; Yellow on black
; Positions of game burders
BORD_R	EQU	77		; Right border
BORD_L	EQU	8		; Left border
BORD_B	EQU	23		; Bottom border
BORD_T	EQU	1		; Top border
; Positions of BUG Zone borders
ZONEB_R EQU	7		; Right border
ZONEB_L EQU	4		; Left border
ZONEB_T EQU	3		; Top border
ZONEB_B EQU	18		; Bottom border
; Position of BUG
HIDEB	DB	0		; 0 - draw BUG; 1 - hide BUG
BUG_R	DB	?		; Row position of BUG
BUG_C	DB	?		; Column position of BUG
; Number of attempts
ATT	DB	?		; Number of shots attempted
; Brain character, position, direction, and range left
BRAIN	EQU	0ECH		; Brain character
BRN_R	DB	?		; Brain row position
BRN_C	DB	?		; Brain column position
BRN_HDIR DB	?		; Horizontal direction: 0=;left, FF=right
BRN_VDIR DB	?		; Vertical direction: 0=up, FF=down
RNG_MAX DB	?		; Maximum brain distance for current level
RNG_BRN DB	?		; Distance traveled by brain
RNG_LFT DB	?		; Distance left
RNG_DEC DB	?		; Traces number of decrements for RANGE label
; Directions (for movement of BUG)
D_TUR	DB	0		; Turret: 0 - up; else - down
D_UP	EQU	48H		; UP key
D_DOWN	EQU	50H		; DOWN key
D_LEFT	EQU	4BH		; LEFT key
D_RIGHT EQU	4DH		; RIGHT key
; --------------------------------------------------------------------------
; MAIN Program
; --------------------------------------------------------------------------
MAIN:	CALL	INTRO		; Load introduction
	CALL	MENU		; Load menu
; Return everything and exit
	MOV	BL, C_DOS	; Set DOS colors
	CALL	CLS		; Blank the screen
	MOV	DL, DOSC_C	; Reset to original cursor column
	MOV	DH, 0		; First line
	CALL	SETCUR
;
	INT	20H
; --------------------------------------------------------------------------
; CALL	INTRO		Displays the introduction
;
;	(No input required)
; --------------------------------------------------------------------------
INTRO		PROC
; Paint screen black
	MOV	BL, 0			; Black background
	CALL	CLS
; Paint opening screen
	LEA	SI, S_SKIP		; "Press any key to continue..."
	MOV	DH, 22			; Row
	MOV	DL, 60			; Column
	MOV	BL, C_INTRO2		; Color scheme
	CALL	PRINTSTR
	MOV	EFF, 0FFH		; Turn on 'typing' effect
	LEA	SI, S_INTRO		; Load opening text
	MOV	DH, 5			; Row
	MOV	DL, 10			; Column
	MOV	BL, C_INTRO1		; Color scheme
	CALL	PRINTSTR
	MOV	EFF, 0			; Turn off 'typing' effect
	MOV	AH, 0			; Wait for user to press key
	INT	16H
;
	RET
INTRO		ENDP
; --------------------------------------------------------------------------
; CALL	MENU		Displays the menu
;
;	(No input required)
; --------------------------------------------------------------------------
MENU		PROC
	PUSH	AX			; Save registers
	PUSH	BX
; Clear the screen
MENU1:	MOV	BL, 0			; Black
	CALL	CLS
; Initialize PLAYER string
	MOV	DI, 0			; Initialize offset
INITP:	MOV	PLAYER[DI], ' '		; Put all spaces in player name
	INC	DI
	CMP	DI, 9			; ... in first 8 characters
	JB	INITP
; Initialize FNAME string with all 0's
	MOV	DI, 0
INITF:	MOV	FNAME[0], 0		; Put all zeros in file name
	INC	DI
	CMP	DI, 15			; at last char?
	JB	INITF
; Paint the logo
	LEA	SI, S_LOGO		; Load logo
	MOV	DH, 2			; Row
	MOV	DL, 5			; Column
	MOV	BL, C_INTRO2		; Color scheme
	CALL	PRINTSTR
; Paint Menu items
	LEA	SI, S_MENU		; Load menu string
	MOV	DH, 12			; Row
	MOV	DL, 50			; Column
	MOV	BL, C_INTRO1		; Color scheme
	CALL	PRINTSTR
; Print brain 'cursor'
	MOV	DH, MENU_ROW		; Row
	MOV	DL, MENU_COL		; Column
	MOV	CX, 1			; 1 char at a time
	MOV	BL, C_BRN		; Color scheme
	MOV	AL, BRAIN		; Character
	CALL	PAINT
; Wait for user to do something
GETACT:	MOV	AH, 0			; Read a key
	INT	16H
	MOV	AL, MENU_ROW		; Save cursor location
	CMP	AH, D_UP		; Pressed UP?
	JE	M_UP
	CMP	AH, D_DOWN		; Pressed DOWN?
	JE	M_DOWN
	CMP	AH, 1CH			; Pressed ENTER?
	JE	DOACT
	JMP	GETACT			; Otherwise, get new key
; Help a brotha jump!
MENU2:	JMP	MENU1
; Move cursor up
M_UP:	CMP	AL, MENU_INST		; At top row?
	JE	GETACT			; ... if yes, neglect
	MOV	DH, MENU_ROW		; Row
	MOV	DL, MENU_COL		; Column
	MOV	CX, 1			; 1 char
	MOV	BL, C_BRN		; Color scheme
	MOV	AL, ' '			; SPACE temporarily hides cursor
	CALL	PAINT
	SUB	MENU_ROW, 2		; Go 2 rows down
	MOV	DH, MENU_ROW		; Set new row
	MOV	AL, BRAIN		; Set BRAIN character
	CALL	PAINT
	JMP	GETACT			; Get new key
; Move cursor down
M_DOWN:	CMP	AL, MENU_EXIT		; At bottom row?
	JE	GETACT			; ... if yes, neglect
	MOV	DH, MENU_ROW		; Row
	MOV	DL, MENU_COL		; Column
	MOV	CX, 1			; 1 char
	MOV	BL, C_BRN		; Color scheme
	MOV	AL, ' '			; SPACE temporarily hides cursor
	CALL	PAINT
	ADD	MENU_ROW, 2		; Go 2 rows up
	MOV	DH, MENU_ROW		; Set new row
	MOV	AL, BRAIN		; Set BRAIN character
	CALL	PAINT
	JMP	GETACT			; Get new key
; User pressed ENTER. Do the action
DOACT:	CMP	AL, MENU_EXIT		; Is EXIT highlighted?
	JE	XMENU1
	CMP	AL, MENU_STRT		; Is START GAME highlighted?
	JE	STARTG
	CMP	AL, MENU_LOAD		; Is LOAD GAME highlighted?
	JE	LOADG1
	CMP	AL, MENU_INST		; Is INSTRUCTIONS highlighted?
	JE	LOADINST
	JMP	MENU2			; Otherwise, go back to menu
;
STARTG: LEA	SI, S_ENTERN		; Load string
	MOV	DH, 20			; Row
	MOV	DL, 6			; Column
	MOV	BL, C_INTRO1		; Color scheme
	CALL	PRINTSTR
	ADD	DL, 12			; Place cursor after text
; Get user's name (8 character max)
	MOV	DI, 0			; Offset for PLAYER string
GETCH:	CALL	SETCUR			; Show the cursor
	MOV	AH, 0			; Get character
	INT	16H
	CMP	AH, 1CH			; Pressed ENTER?
	JNE	SAVECHAR		; ... if not, store char
	CMP	DI, 0			; ENTER only char pressed?
	JE	MENU3			; ... if so, go back to menu
	JMP	CRFILE			; ... otherwise, create file
SAVECHAR:MOV	PLAYER [DI], AL		; Save character
	MOV	CX, 1			; Echo whatever was typed
	CALL	PAINT
	INC	DL			; Move over one column
	INC	DI			; Increment string offset
	CMP	DI, 8			; 8 character maximum
	JB	GETCH			; ... keep going if below g
	JMP	CRFILE			; ... otherwise, create the file
; Help a brotha jump!
MENU3:	JMP	MENU2
XMENU1:	JMP	XMENU
LOADG1:	JMP	LOADG
;
; Load instruction screen
LOADINST: CALL	INSTRUCT
	JMP	MENU2		; Then go back
;
; Create saved game file
CRFILE:	MOV	DI, 0		; Initialize offset
CRFNAME: MOV	AL, PLAYER[DI]	; Get character
	CMP	AL, ' '		; At end of name?
	JE	APPEND		; ... if so, add extention
	MOV	FNAME[DI], AL	; ... otherwise, keep getting chars
	INC	DI
	JMP	CRFNAME
; Now, add .DAT extension to filename
APPEND:	MOV	FNAME[DI], '.'
	INC	DI		; Next char
	MOV	FNAME[DI], 'D'
	INC	DI		; Next char
	MOV	FNAME[DI], 'A'
	INC	DI		; Next char
	MOV	FNAME[DI], 'T'
; Create file
	MOV	AH, 3CH		; Create file
	MOV	CX, 0		; No special attributes
	LEA	DX, FNAME	; Load file name
	INT	21H
	JNC	NOERR1
; If error, print error message
	MOV	DH, 22		; Row
	MOV	DL, 6		; Column
	MOV	BL, C_INTRO2	; Color scheme
	LEA	SI, S_ERR1	; Load string
	CALL	PRINTSTR
	MOV	AH, 0		; Wait for user to press a key
	INT	16H
MENU4:	JMP	MENU3		; Go back
NOERR1:	MOV	FHANDLE, AX	; Save handle
; Save initial data
	MOV	AH, 40H		; Write to file
	MOV	BX, FHANDLE	; Load handle
	MOV	CX, 12		; Write all 12 bytes in FDATA
	LEA	DX, FDATA	; Load FDATA string
	INT	21H
; Close file
	CALL	CLOSEFILE	; Close the file
	CALL	INITFDATA	; Initialize FDATA
	JMP	STARTGAME	; Start the game
;
; // Done creating saved game file //
;
; Load a Game
LOADG:	 LEA	SI, S_ENTERN		; Load string
	MOV	DH, 20			; Row
	MOV	DL, 6			; Column
	MOV	BL, C_INTRO1		; Color scheme
	CALL	PRINTSTR
	ADD	DL, 12			; Place cursor after text
; Get user's name (8 character max)
	MOV	DI, 0			; Offset for PLAYER string
GETCH1:	CALL	SETCUR			; Show the cursor
	MOV	AH, 0			; Get character
	INT	16H
	CMP	AH, 1CH			; Pressed ENTER?
	JNE	SAVECHAR1		; ... if not, store char
	CMP	DI, 0			; ENTER only char pressed?
	JE	MENU4			; ... if so, go back to menu
	JMP	OPFILE			; ... otherwise, create file
SAVECHAR1: MOV	PLAYER [DI], AL		; Save character
	MOV	CX, 1			; Echo whatever was typed
	CALL	PAINT
	INC	DL			; Move over one column
	INC	DI			; Increment string offset
	CMP	DI, 8			; 8 character maximum
	JB	GETCH1
OPFILE:	MOV	DI, 0		; Initialize offset
OPFNAME: MOV	AL, PLAYER[DI]	; Get character
	CMP	AL, ' '		; At end of name?
	JE	APPEND1		; ... if so, add extention
	MOV	FNAME[DI], AL	; ... otherwise, keep getting chars
	INC	DI		; Next character
	JMP	OPFNAME		; Get more characters
; Now, add .DAT extension to filename
APPEND1: MOV	FNAME[DI], '.'
	INC	DI		; Next char
	MOV	FNAME[DI], 'D'
	INC	DI		; Next char
	MOV	FNAME[DI], 'A'
	INC	DI		; Next char
	MOV	FNAME[DI], 'T'
; Open the file
	MOV	AH, 3DH		; Open file
	MOV	AL, 0		; Open for reading
	LEA	DX, FNAME	; Load filename string
	INT	21H
	JC	ERR2		; Carry flag set if ERROR
	MOV	FHANDLE, AX	; Otherwise, save handle
; Read from the file
	MOV	AH, 3FH		; Read from file
	MOV	BX, FHANDLE	; Load handle
	MOV	CX, 12		; Read all 12 bytes
	LEA	DX, FDATA	; Store them in FDATA (will overwrite)
	INT	21H
	JC	ERR2		; Error sets carry flag
	JMP	STARTGAME	; Otherwise, start the game!
; If error, print error message
ERR2:	MOV	DH, 22		; Row
	MOV	DL, 6		; Column
	MOV	BL, C_INTRO2	; Color scheme
	LEA	SI, S_ERR2	; Print error message
	CALL	PRINTSTR
	MOV	AH, 0		; Wait for user to hit a key
	INT	16H
	JMP	MENU4		; Go back to menu
; Load level 1 and start
STARTGAME: CALL	INIT		; Initialize game board
	CALL	PLAYBUG		; Start playing
	MOV	MENU_ROW, 12	; Reset menu cursor at top
	JMP	MENU3		; Go back to menu
;
XMENU:	POP	BX		; Return registers
	POP	AX
	RET
MENU		ENDP
; --------------------------------------------------------------------------
; CALL	INSTRUCT	Displays the game instructions.
; --------------------------------------------------------------------------
INSTRUCT	PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
;
; First, clear the screen
	MOV	BL, C_INTRO1	; Color: White on black
	CALL	CLS
; Now, print borders for instructions
; Start with top borders
	MOV	AL, 0C9H	; Top left border
	MOV	CX, 1		; 1 character
	MOV	DH, 3		; Row
	MOV	DL, 14		; Column
	CALL	PAINT
	MOV	AL, 0CDH	; Top border characcter
	MOV	CX, 50		; 50 characters
	INC	DL		; Move one column over
	CALL	PAINT
	MOV	AL, 0BBH	; Top right border character
	MOV	CX, 1		; 1 character
	ADD	DL, 50		;Move 50 columns over (after painting 50 chars)
	CALL	PAINT
; Now, print side borders
	MOV	AX, 0BAH	; Side border character
BORLP:	MOV	DL, 14		; Start from left side (col 14)
	INC	DH		; New row
	CMP	DH, 20		; At last row?
	JAE	PRMID		; ... if so, print middle border
	CALL	PAINT
	MOV	DL, 65		; Now paint right side (col 65)
	CALL	PAINT
	JMP	BORLP		; Keep going
; Print middle border
PRMID:	MOV	AL, 0CDH	; Middle border character
	MOV	CX, 50		; 50 chars
	MOV	DH, 14		; Row 14
	MOV	DL, 15		; Column 15
	CALL	PAINT
; Print bottom border
	MOV	AL, 0C8H	; Bottom-left border
	MOV	CX, 1		; 1 character
	MOV	DH, 20		; Row
	MOV	DL, 14		; Column
	CALL	PAINT
	MOV	AL, 0CDH	; Bottom border characcter
	MOV	CX, 50		; 50 characters
	INC	DL		; Move one column over
	CALL	PAINT
	MOV	AL, 0BCH	; Bottom-right border character
	MOV	CX, 1		; 1 character
	ADD	DL, 50		; Move 50 columns over
	CALL	PAINT
; Print "press any key to continue"
	MOV	DH, 22		; Row
	MOV	DL, 50		; Column
	MOV	BL, C_INTRO2	; Color scheme
	LEA	SI, S_OUTRO7	; Load string
	CALL	PRINTSTR
; \\ First set of instructions
; Begin with drawing the GOAL
	MOV	AL, '>'		; GOAL character
	MOV	DH, 5		; Row
	MOV	DL, 38		; Column
	MOV	BL, 22H		; Top part of GOAL
	MOV	CX, 3		; Width 3
	CALL	PAINT
	INC	DH		; Mov down a row
I1LP:	MOV	BL, 0EEH	; Color scheme for '>' (blinking)
	MOV	CX, 2		; 2 characters
	CALL	PAINT
	MOV	BL, 22H		; Now, paint right edge (Green)
	MOV	CX, 1		; 1 character
	ADD	DL, 2		; Move over 2 columns
	CALL	PAINT
	SUB	DL, 2		; Now, move back 2 columns
	INC	DH		; Move down a row
	CMP	DH, 12		; Done drawing?
	JB	I1LP
	MOV	BL, 22H		; Bottom part
	MOV	CX, 3		; Width 3
	CALL	PAINT
; Now, draw the text
	MOV	DH, 16		; Row
	MOV	DL, 22		; Column
	MOV	BL, C_INTRO1	; Color scheme
	LEA	SI, S_INST1	; Load string
	CALL	PRINTSTR
; Wait for a key to be pressed
	MOV	AH, 0		; Wait for key
	INT	16H
	CALL	CLRBOXES	; Clear the box area
; \\ Second set of instructions
; Draw the BUG first
	MOV	AL, 'X'		; BUG character
	MOV	BL, C_BUG	; Color: Green on black
	MOV	CX, 3		; 3 characters
	MOV	DH, 7		; Row
	MOV	DL, 38		; Column
	CALL	PAINT
	INC	DH		; Draw next row
	CALL	PAINT
	INC	DH		; Draw next row
	CALL	PAINT
	INC	DH		; Draw next row
	CALL	PAINT
	SUB	DH, 2		; Draw turret (on 2nd row)
	ADD	DL, 3		; Adjust column
	MOV	AL, '/'		; Turret character
	MOV	CX, 1		; 1 char
	CALL	PAINT
; Now, draw the text
	MOV	DH, 16		; Row
	MOV	DL, 20		; Column
	MOV	BL, C_INTRO1	; Color scheme
	LEA	SI, S_INST2	; Load string
	CALL	PRINTSTR
; Wait for a key to be pressed
	MOV	AH, 0		; Wait for key
	INT	16H
; \\ Third set of instructions
; Add BRAIN to sketch
	MOV	AL, BRAIN	; Brain character
	MOV	BL, C_BRN	; Color scheme
	MOV	CX, 1		; 1 character
	MOV	DH, 6		; Row
	MOV	DL, 44		; Column
	CALL	PAINT
; Now, draw the text
	MOV	DH, 16		; Row
	MOV	DL, 20		; Column
	MOV	BL, C_INTRO1	; Color scheme
	LEA	SI, S_INST3	; Load string
	CALL	PRINTSTR
; Wait for a key to be pressed
	MOV	AH, 0		; Wait for key
	INT	16H
	CALL	CLRBOXES	; Clear the box area
; \\ Fourth set of instructions
; Print RANGE label
	MOV	BL, C_STATUS	; Color scheme
	MOV	DH, 8		; Row
	MOV	DL, 34		; Column
	LEA	SI, S_RANGE	; Load string
	CALL	PRINTSTR
	MOV	AL, 04H		; SPADES character
	MOV	BL, C_RNG	; Color scheme
	MOV	CX, 5		; 5 characters
	ADD	DL, 7		; Column offset
	CALL	PAINT
; Now, draw the text
	MOV	DH, 16		; Rw
	MOV	DL, 17		; Column
	MOV	BL, C_INTRO1	; Color scheme
	LEA	SI, S_INST4	; Load string
	CALL	PRINTSTR
; Wait for a key to be pressed
	MOV	AH, 0		; Wait for key
	INT	16H
	CALL	CLRBOXES	; Clear box area
; \\ Fifth set of instructions
; Print SOUND label
	MOV	BL, C_STATUS	; Color scheme
	MOV	DH, 8		; Row
	MOV	DL, 34		; Column
	LEA	SI, S_SOUND	; Load string
	CALL	PRINTSTR
	ADD	DL, 7		; Column offset
	LEA	SI, S_OFF	; Load string
	CALL	PRINTSTR
; Now, draw the text
	MOV	DH, 16		; Row
	MOV	DL, 17		; Column
	MOV	BL, C_INTRO1	; Color scheme
	LEA	SI, S_INST5	; Load string
	CALL	PRINTSTR
; Wait for a key to be pressed
	MOV	AH, 0		; Wait for key
	INT	16H
	CALL	CLRBOXES	; Clear the box area
; \\ Sixth set of instructions
; Print DELAY label
	MOV	BL, C_STATUS	; Color scheme
	MOV	DH, 8		; Row
	MOV	DL, 34		; Column
	LEA	SI, S_DELAY	; Load string
	CALL	PRINTSTR
	ADD	DL, 7		; Column offset
	MOV	BX, 50		; Will print DELAY: 50
	CALL	PRINTNUM
; Now, draw the text
	MOV	DH, 16		; Row
	MOV	DL, 17		; Column
	MOV	BL, C_INTRO1	; Color scheme
	LEA	SI, S_INST6	; Load string
	CALL	PRINTSTR
; Wait for a key to be pressed
	MOV	AH, 0		; Wait for key
	INT	16H
;
	POP	DX		; Return registers
	POP	CX
	POP	BX
	POP	AX
	RET
INSTRUCT	ENDP
; --------------------------------------------------------------------------
; CALL	CLRBOXES	Routine used to clear boxes in INSTRUCTIONS screen
; --------------------------------------------------------------------------
CLRBOXES	PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
;
	MOV	AL, ' '		; Print spaces
	MOV	BL, C_INTRO1	; Color scheme (black)
	MOV	CX, 50		; 50 chars at a time
;
	MOV	DH, 4		; Row
	MOV	DL, 15		; Column
; Move through all the necessary rows
CLRLP:	CALL	PAINT
	INC	DH		; Next row
	CMP	DH, 20		; At last row?
	JE	XCLR
	CMP	DH, 14		; At row 14? If so, skip (has a border drawn)
	JNE	CLRLP
	INC	DH		; ... skip
	JMP	CLRLP
;
XCLR:	POP	DX		; Return registers
	POP	CX
	POP	BX
	POP	AX
	RET
CLRBOXES	ENDP
; --------------------------------------------------------------------------
; CALL	INITFDATA	Initializes values in FDATA
;			1, 0FFH, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0
; --------------------------------------------------------------------------
INITFDATA	PROC
;
	MOV	FDATA[0], 1	; Default values
	MOV	FDATA[1], 0FFH
	MOV	FDATA[2], 50
	MOV	FDATA[3], 0
	MOV	FDATA[4], 0
	MOV	FDATA[5], 0
	MOV	FDATA[6], 0
	MOV	FDATA[7], 0
	MOV	FDATA[8], 0
	MOV	FDATA[9], 0
	MOV	FDATA[10], 0
	MOV	FDATA[11], 0
;
	RET
INITFDATA	ENDP
; --------------------------------------------------------------------------
; CALL	SAVEFILE	Saves game data into file pointed by FHANDLE
;			This procedure will close the file automatically.
;  INPUT:
;	FHANDLE		Game handle
;  OUTPUT:
;	FERR
; --------------------------------------------------------------------------
SAVEFILE	PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
; Create file
	MOV	AH, 3CH		; Create file
	MOV	CX, 0		; No special attributes
	LEA	DX, FNAME	; Load file name
	INT	21H
; Load all the data into FDATA
	MOV	AL, CURLEV	; Load current level
	MOV	FDATA[0], AL	; Save current level
	MOV	AL, SOUND	; Load sound setting
	MOV	FDATA[1], AL	; Save sound setting
	MOV	AL, SPEED	; Load delay setting
	MOV	FDATA[2], AL	; Save delay setting
; Log attempts
	MOV	AX, 2		; First level begins at position 3
	ADD	AL, CURLEV	; Level number will give correct offset
	MOV	DI, AX		; 	e.g. Level 4 attempts are at FDATA[6]
	MOV	AL, ATT
	MOV	FDATA[DI], AL	; Save attempts
; Write the data to file
	MOV	AH, 40H		; Write to file
	MOV	BX, FHANDLE	; Load handle
	MOV	CX, 12		; Write all 12 bytes in FDATA
	LEA	DX, FDATA	; Load data address
	INT	21H
; Close the file
	CALL	CLOSEFILE
;
	POP	DX		; Return registers
	POP	CX
	POP	BX
	POP	AX
	RET
SAVEFILE	ENDP
; --------------------------------------------------------------------------
; CALL	LOADFILE		Loads a game into FDATA
;
;	FNAME		File name
; --------------------------------------------------------------------------
LOADFILE	PROC
	PUSH	AX		; Save registers
	PUSH	BX
; Open the file
	MOV	AH, 3DH		; Open file
	MOV	AL, 0		; Open for reading
	LEA	DX, FNAME	; Load filename
	INT	21H
	MOV	FHANDLE, AX	; Save handle
; Read from the file
	MOV	AH, 3FH		; Read from file
	MOV	BX, FHANDLE	; Load handle
	MOV	CX, 12		; Read all 12 bytes
	LEA	DX, FDATA	; Load FDATA address
	INT	21H
;
	POP	BX		; Return registers
	POP	AX
	RET
LOADFILE	ENDP
; --------------------------------------------------------------------------
; CALL	CLOSEFILE		Opens a game and saves handle in FHANDLE
;
;	FHANDLE		File name
; --------------------------------------------------------------------------
CLOSEFILE	PROC
	PUSH	AX		; Save registers
	PUSH	BX
;
	MOV	AH, 3EH		; Close file
	MOV	BX, FHANDLE	; Load handle
	INT	21H
;
	POP	BX		; Return registers
	POP	AX
	RET
CLOSEFILE	ENDP
; --------------------------------------------------------------------------
; CALL	INIT		Initializes screen for gameplay
;
;	(No input required)
; --------------------------------------------------------------------------
INIT		PROC
; Store level memory locations
	LEA	SI, LVL1
	MOV	LEVS[0], SI	; Level 1
	LEA	SI, LVL2
	MOV	LEVS[2], SI	; Level 2
	LEA	SI, LVL3
	MOV	LEVS[4], SI	; Level 3
	LEA	SI, LVL4
	MOV	LEVS[6], SI	; Level 4
	LEA	SI, LVL5
	MOV	LEVS[8], SI	; Level 5
	LEA	SI, LVL6
	MOV	LEVS[10], SI	; Level 6
	LEA	SI, LVL7
	MOV	LEVS[12], SI	; Level 7
	LEA	SI, LVL8
	MOV	LEVS[14], SI	; Level 8
	LEA	SI, LVL9
	MOV	LEVS[16], SI	; Level 9
; Load FDATA
	MOV	AL, FDATA[0]	; Get level number
	MOV	CURLEV, AL
	MOV	AL, FDATA[1]	; Get sound preference
	MOV	SOUND, AL
	MOV	AL, FDATA[2]	; Get delay setting
	MOV	SPEED, AL
	MOV	AX, 2		; Now, go to current level
	ADD	AL, CURLEV	; ... will be FDATA[2 + CURLEV]
	MOV	DI, AX
	MOV	AL, FDATA[DI]	; Load attempts for level
	MOV	ATT, AL
; Did we beat the game? Show end screen
	CMP	CURLEV, 10
	JE	ENDGAME1
; Remember DOS cursor position and clear screen
	MOV	AH, 3		; Read cursor pos
	MOV	BH, 0		; Video page 0
	INT	10H
	MOV	DOSC_C, DL	; Load DOS colors
	MOV	BL, C_DOS	; Color scheme
	CALL	CLS		; Clear the screen
	CALL	HIDEBUG		; Hide the BUG
; Paint top and bottom game borders
	MOV	AL, 'W'		; 'W' character
	MOV	DX, 0		; Start from (0,0)
	MOV	CX, 80		; 80 characters
	MOV	BL, C_WALL	; Color scheme
	CALL	PAINT
	MOV	DH, 24		; Row 24
	CALL	PAINT
; Paint left and right game borders
	MOV	DH, 1		; Begin with row 1
	MOV	CX, 2		; 2 characters
PTSIDES: MOV	DL, 0		; Left side
	CALL	PAINT
	MOV	DL, 78		; Right side
	CALL	PAINT
	ADD	DH, 1		; New row
	CMP	DH, 25		; Last column
	JB	PTSIDES
; Paint borders of BUG zone
	MOV	BL, 1111B	; Set color to white
	MOV	AL, 0CDH	; Top border character
	MOV	CX, 5		; 5 characters
	MOV	DH, 1		; Row
	MOV	DL, 2		; Column
	CALL	PAINT
	MOV	AL, 0BBH	; Top-right corner character
	MOV	CX, 1		; 1 character
	MOV	DL, 7		; Colun
	CALL	PAINT
	JMP	SIDEB
; Help a brotha jump!
ENDGAME1: JMP	ENDGAME
;
SIDEB:	INC	DH		; Go down, row by row
	MOV	AL, 0BAH	; Right border character
	CALL	PAINT
	CMP	DH, 21		; Row
	JBE	SIDEB
	MOV	AL, 0BCH	; Bottom-right border character
	INC	DH		; Next row
	CALL	PAINT
	MOV	AL, 0CDH	; Bottom border character
	MOV	CX, 5		; 5 characters
	MOV	DL, 2		; Column
	CALL	PAINT
; Paint Delay label
	MOV	DH, 0		; Row
	MOV	DL, 68		; Column
	LEA	SI, S_DELAY	; Load string
	MOV	BL, C_STATUS	; Color scheme
	CALL	PRINTSTR
; Print the Delay
	MOV	DL, 74		; Column
	MOV	BL, SPEED	; Load speed
	CALL	PRINTNUM
; Print Sound label
	MOV	DL, 3		; Column
	MOV	BL, C_STATUS	; Color scheme
	LEA	SI, S_SOUND	; Load string
	CALL	PRINTSTR
; Print Sound ON/OFF
	MOV	DL, 10		; Column
	CMP	SOUND, 0	; Sound ON or OFF?
	JE	PR_OFF
	LEA	SI, S_ON	; Load string
	CALL	PRINTSTR
	JMP	PRLEV
PR_OFF:	LEA	SI, S_OFF	; Load string
	CALL	PRINTSTR
; Print Level label
PRLEV:	MOV	DH, 24
	MOV	DL, 31
	LEA	SI, S_LEVEL	; Load string
	MOV	BL, C_STATUS
	CALL	PRINTSTR
; Load Level
	LEA	SI, LVL1	; Load level
	CALL	LOADLEV
; Print Attempts label
	MOV	DL, 3		; Column
	MOV	BL, C_STATUS	; Color scheme
	LEA	SI, S_ATT	; Load string
	CALL	PRINTSTR
; Print range label
	MOV	DL, 65		; Column
	LEA	SI, S_RANGE	; Load string
	MOV	BL, C_STATUS	; Color scheme
	CALL	PRINTSTR
; Print distance left
	CALL	PRINTRNG
; Initially place the BUG
	MOV	BUG_R, 5	; Initial row
	MOV	BUG_C, 3	; Initial column
	CALL	DRAWBUG		; Draw the bug
	CALL	HIDECUR		; Get rid of cursor
;
	RET
INIT		ENDP
; --------------------------------------------------------------------------
; CALL	CLS		Clears the screen
; --------------------------------------------------------------------------
CLS		PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
;
	MOV	AL, ' '		; Fill screen with black
	MOV	CX, 80*25	; Entire screen
	MOV	DX, 0		; Starting from (0,0)
	CALL	PAINT
;
	POP	DX		; Return registers
	POP	CX
	POP	BX
	POP	AX
	RET
CLS		ENDP
; --------------------------------------------------------------------------
; CALL	PAINT		Paints characters onto screen
;
;	AL		Character to print
;	BL		Color
;	CX		Number of characters to print
;	DH, DL		Row, column of first character
; --------------------------------------------------------------------------
PAINT		PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
;
	CMP	CX, 0		; If no characters, exit
	JE	XPAINT
	CALL	SETCUR		; Set cursor position
	MOV	BH, 0		; Video page 0
	MOV	AH, 9		; Write character
	INT	10H
	CALL	HIDECUR
;
XPAINT: POP	DX		; Return registers
	POP	CX
	POP	BX
	POP	AX
	RET
PAINT		ENDP
; --------------------------------------------------------------------------
; CALL	SETCUR		Sets the cursor position
;
;	DH, DL		Row, column of cursor
; --------------------------------------------------------------------------
SETCUR		PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	DX
;
	MOV	BH, 0		; Video page 0
	MOV	AH, 2		; Set cursor
	INT	10H
;
	POP	DX		; Return registers
	POP	BX
	POP	AX
	RET
SETCUR		ENDP
; --------------------------------------------------------------------------
; CALL	HIDECUR		Hides the cursor
; --------------------------------------------------------------------------
HIDECUR		PROC
	PUSH	AX		; Save registers
	PUSH	CX
	PUSH	DX
;
	MOV	DH, 25		; Put cursor out of sight
	MOV	DL, 0
	CALL	SETCUR
;
	POP	DX		; Return registers
	POP	CX
	POP	AX
	RET
HIDECUR		ENDP
; --------------------------------------------------------------------------
; CALL	HIDEBUG		Temporarily hides the bug
; --------------------------------------------------------------------------
HIDEBUG		PROC
	MOV	HIDEB, 1	; Set HIDE to YES
	CALL	DRAWBUG		; and draw the bug
	RET
HIDEBUG		ENDP
; --------------------------------------------------------------------------
; CALL	DRAWBUG		Draws the bug
;
;	HIDEB		If set to 1, will hide the BUG instead of drawing it
; --------------------------------------------------------------------------
DRAWBUG		PROC
	PUSH	AX			; Save registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
;
	MOV	DH, BUG_R		; Set position
	MOV	DL, BUG_C
	MOV	BL, C_BUG		; Set color scheme
;
	CMP	HIDEB, 1		; Hide or draw?
	JNZ	DRAW1			; ... draw the bug
	MOV	AL, ' '			; ... draw a blank
	MOV	BL, 0			; Video page 0
	JMP	DRAW2
DRAW1:	MOV	AL, 'X'			; Character
	MOV	BL, C_BUG		; Color
DRAW2:	MOV	CX, 3			; Number of Chars
	CALL	PAINT			; First row of BUG
	INC	DH
	CALL	PAINT			; Second Row
	INC	DH
	CALL	PAINT			; Third Row
	INC	DH
	CALL	PAINT			; Fourth Row
; Draw Turret
	MOV	DH, BUG_R		; Get BUG row
	MOV	DL, BUG_C		; Get BUG column
	MOV	CX, 1			; 1 character
	ADD	DL, 3			; Row
;
	MOV	AL, ' '			; Space hides
	CMP	D_TUR, 0		; UP or DOWN?
	JNE	DRAW4
;
	CMP	HIDEB, 1		; Are we hiding?
	JE	DRAW3			; If so, keep the space
	MOV	AL, '/'			; Sets turret UP
DRAW3:	ADD	DH, 1			; Next row
	CALL	PAINT
	JMP	XDRAW
DRAW4:	CMP	HIDEB, 1
	JE	DRAW5
	MOV	AL, '\'			; Sets turret DOWN
DRAW5:	ADD	DH, 2			; Row
	CALL	PAINT
;
XDRAW:	MOV	HIDEB, 0		; HIDE set to no
	CALL	HIDECUR			; Hide the cursor
;
	POP	DX			; Return registers
	POP	CX
	POP	BX
	POP	AX
	RET
DRAWBUG		ENDP
; --------------------------------------------------------------------------
; CALL	PLAYBUG			Moves the BUG
; --------------------------------------------------------------------------
PLAYBUG		PROC
	PUSH	AX			; Save registers
	PUSH	BX
;
GETMOV: CMP	NEWLEV, 0		; Start a new level?
	JNE	NXTLEV1
	CALL	HIDECUR
	MOV	AH, 0
	INT	16H			; Key pressed?
; See if user pressed arrow keys.
	CMP	AH, D_RIGHT		; Toggle direction
	JE	TOG_D
	CMP	AH, D_LEFT		; Toggle direction
	JE	TOG_D
	CMP	AH, D_UP		; Move BUG up
	JE	MOV_U
	CMP	AH, D_DOWN		; Move BUG down
	JE	MOV_D
	CMP	AL, 'S'			; Toggle sound?
	JE	TOG_SND
	CMP	AL, 's'			; Toggle sound?
	JE	TOG_SND
; See if user pressed SPACEBAR
	CMP	AH, 39H			; pressed SPACEBAR? Shoot!
	JE	SHOOT
; See if user pressed any other action keys
	CMP	AH, 49H			; pressed PAGE UP? Increase speed
	JE	FASTER1
	CMP	AH, 51H			; pressed PAGE DOWN? Decrease speed
	JE	SLOWER1
	CMP	AH, 1CH			; pressed ENTER? skip level!
	JE	NXTLEV1
	CMP	AL, 1BH			; pressed ESCAPE? Quit.
	JE	XPLAYBUG1
	JMP	PLAYBUG
; Move down
MOV_D:	CMP	BUG_R, ZONEB_B		; Moving out of range?
	JA	GETMOV			; ... if yes, neglect
	CALL	HIDEBUG
	INC	BUG_R			; Move one row down
	CALL	DRAWBUG
	JMP	GETMOV
; Move up
MOV_U:	CMP	BUG_R, ZONEB_T		; Moving out of range?
	JB	GETMOV			; ... if yes, neglect
	CALL	HIDEBUG
	DEC	BUG_R			; Move one row up
	CALL	DRAWBUG
	JMP	GETMOV
; Toggle turret direction (SPACEBAR)
TOG_D:	CALL	HIDEBUG			; Hide the bug
	NOT	D_TUR			; Change direction of turret
	CALL	DRAWBUG			; Draw new bug
; Help a brotha jump!
GETMOV1: JMP	GETMOV
XPLAYBUG1: JMP	XPLAYBUG
FASTER1: JMP	FASTER
SLOWER1: JMP	SLOWER
NXTLEV1: JMP	NXTLEV
;
; Toggle Sound on/off
TOG_SND: NOT	SOUND		; Invert whatever current sound is
	MOV	BL, C_STATUS	; Color scheme
	MOV	DH, 0		; Row
	MOV	DL, 10		; Column
	CMP	SOUND, 0	; Sound ON or OFF?
	JE	PR_OFF1
	LEA	SI, S_ON	; Load ON string
	CALL	PRINTSTR
	JMP	GETMOV1
PR_OFF1: LEA	SI, S_OFF	; Load OFF string
	CALL	PRINTSTR
	JMP	GETMOV1
; Shoot!
SHOOT:	CALL	PLAY
	MOV	AH, RNG_MAX	; Reset Range eft
	MOV	RNG_LFT, AH
	CALL	PRINTRNG
CLRBUF: MOV	AH, 1		; Clear keyboard buffer
	INT	16H
	JZ	GETMOV1
	MOV	AH, 0
	INT	16H
	JMP	CLRBUF
; Increase delay speed
FASTER: CMP	SPEED, 99	; Speed out of range?
	JE	NEWMOV		; ... if so, neglect
	ADD	SPEED, 1	; Increase speed
	MOV	DH, 0		; Row
	MOV	DL, 74		; Column
	MOV	BL, SPEED	; Color scheme
	CALL	PRINTNUM
	JMP	NEWMOV
; Decrease delay speed
SLOWER: CMP	SPEED, 1	; Speed out of range?
	JE	NEWMOV		; ... if so, neglect
	SUB	SPEED, 1	; Decrease speed
	MOV	DH, 0		; Row
	MOV	DL, 74		; Column
	MOV	BL, SPEED	; Color scheme
	CALL	PRINTNUM
; If nothing was pressed, try again
NEWMOV: JMP	GETMOV1
; Save game
NXTLEV: CALL	SAVEFILE	; Save upon completing level
	CMP	CURLEV, 9	; At last level?
	JNB	ENDGAME
	INC	CURLEV		; Increase current level
	MOV	ATT, 0		; Re-initialize attempts
; Load next level
	CALL	LOADLEV		; Load new level
	JMP	GETMOV1
ENDGAME: CALL	OUTRO		; Show closing sequence
;
XPLAYBUG: CALL	SAVEFILE	; Save upon exiting
	POP	BX
	POP	AX
	RET
PLAYBUG		ENDP
; --------------------------------------------------------------------------
;	CALL	PLAY		Plays the brain
;
;	BRN_DIR			Direction (will change if wall/obstacle hit)
;	BRN_R			Current Row
;	BRN_C			Current Column
; --------------------------------------------------------------------------
PLAY		PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
; Log attempt and print
	INC	ATT		; Increase attempt
	MOV	BL, ATT		; Load number
	MOV	DH, 24		; Row
	MOV	DL, 12		; Column
	CALL	PRINTNUM
; Begin logging distance
	MOV	AH, RNG_MAX	; Get max distance
	MOV	RNG_BRN, AH	; Store in range left
	SUB	AH, RNG_DEC	; Remove the calculated Range decrement
	MOV	RNG_LFT, AH	; and store in RNG_LFT
; Place brain in correct position
	MOV	AL, BUG_C		; Load column position
	MOV	BRN_C, AL		; Store column position
	ADD	BRN_C, 5		; Offset column by 4 right
	MOV	AL, BUG_R		; Load row position
	MOV	BRN_R, AL		; Store row position
; Which direction?
	CMP	D_TUR, 0		; Going up or down?
	JNE	SHT_DWN
	MOV	BRN_VDIR, 0		; Shooting UP
	JMP	PLAY0
SHT_DWN: ADD	BRN_R, 3		; Shooting DOWN? Offset brain row 3
	MOV	BRN_VDIR, 0FFH		; Shooting DOWN
;
PLAY0:	MOV	AL, D_TUR		; Vertical direction of turret
	MOV	BRN_VDIR, AL
	MOV	BRN_HDIR, 0FFH		; Always start by going right
;
; We now have direction and position. Paint the bugger!
PLAY1:	MOV	DH, BRN_R		; Row
	MOV	DL, BRN_C		; Column
	CALL	SETCUR
	MOV	AL, BRAIN		; The brain!
	MOV	BL, C_BRN		; Color scheme
	MOV	CX, 1			; 1 character
	CALL	PAINT
	CALL	DELAY			; Wait a moment
	MOV	AL, ' '			; Spaces hide
	CALL	PAINT			; Hide it!
	JMP	PLAY2
; Check if we hit a wall
PLAY2:	CMP	BRN_R, BORD_T		; Hit top wall?
	JNE	CHKBOT
	NOT	BRN_VDIR		;	yes? change direction
CHKBOT: CMP	BRN_R, BORD_B		; Hit bottom wall?
	JNE	CHKLEFT
	NOT	BRN_VDIR		; ... yes? change direction
CHKLEFT: CMP	BRN_C, BORD_L
	JNE	CHKRIGHT
	MOV	BRN_HDIR, 0FFH		; Hit left wall? Move right
CHKRIGHT: CMP	BRN_C, BORD_R		; at right border?
	JNE	PLAY3A
	NOT	BRN_HDIR		; ... yes? change direction
	JMP	PLAY3A
; Help a brotha jump!
PLAY1A: JMP	PLAY1
; Check if we hit a block
PLAY3A: CALL	NEXTCH
	CMP	AL, 'H'			; Horizontal block?
	JE	PLAY3B
	CMP	AL, 'L'			; Left border?
	JE	PLAY3C
	CMP	AL, 'R'			; Right border?
	JE	PLAY3D
	CMP	AL, '>'			; Hit the goal?
	JE	GOTIT
	JMP	PLAY4
; Help a brotha jump!
PLAY1B:	JMP	PLAY1A
; Horizontal block. Do some special stuff if it's a corner
PLAY3B: NOT	BRN_VDIR
	JMP	PLAY4
PLAY3C: CMP	BRN_HDIR, 0FFH		; For left corners. Going right?
	JNE	PLAY3B
	NOT	BRN_HDIR		; If so, switch direction
	JMP	PLAY4
PLAY3D: CMP	BRN_HDIR, 0		; For right corners. Going left?
	JNE	PLAY3B
	NOT	BRN_HDIR
	JMP	PLAY4
; We now have correct direction. Update positions!
PLAY4:	CMP	BRN_VDIR, 0		; Going up or down?
	JNE	GODOWN
	SUB	BRN_R, 1
	JMP	GOLEFT
GODOWN: ADD	BRN_R, 1
GOLEFT: CMP	BRN_HDIR, 0		; Going left or right?
	JNE	GORIGHT
	SUB	BRN_C, 1
	JMP	NEXTPOS
GORIGHT: ADD	BRN_C, 1
; Update distance remaining. Keep going if distance left
NEXTPOS: DEC	RNG_BRN
	JZ	NOGOOD
	MOV	AH, RNG_LFT
	CMP	AH, RNG_BRN	; Time to decrement range counter?
	JNE	PLAY1B		; ... if not, kep playing
	CALL	PRINTRNG	; Otherwise, print new counter
	SUB	AH, RNG_DEC
	MOV	RNG_LFT, AH
	MOV	AX, 196		; Play a note
	MOV	DX, 4
	CALL	NOTE
	JMP	PLAY1A
;
GOTIT:	NOT	NEWLEV		; Gonna load a new level
	MOV	AX, 392		; Play some tunes!
	MOV	DX, 5
	CALL	NOTE
	MOV	AX, 330
	CALL	NOTE
	MOV	AX, 392
	CALL	NOTE
	MOV	AX, 440
	CALL	NOTE
	JMP	XPLAY
;
NOGOOD:	MOV	AX, 196		; Play
	MOV	DX, 5
	CALL	NOTE
	MOV	AX, 165
	CALL	NOTE
;
XPLAY:	CALL	HIDECUR		; Get rid of cursor
;
	POP	DX		; Return registers
	POP	CX
	POP	BX
	POP	AX
	RET
PLAY		ENDP
; --------------------------------------------------------------------------
; CALL	DELAY			Sets a delay of a certain speed
;
;		Uses a triple nested loop in which the user can set the outer
;		loop value (SPEED).
;
;		If values are completely off, you can increase/decrease
;		D_LOOP, which controls the inner loop
; ---------------------------------------------------------------------------
DELAY		PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	CX
;
	CALL	HIDECUR		; Get rid of cursor
	MOV	AL, SPEED	; Get speed
OUTER:	SUB	AL, 1		; Outer loop
	MOV	BX, D_LOOP
INNER:	SUB	BX, 1		; More loopage
	MOV	CX, D_LOOP
WASTE:	LOOP	WASTE		; Even more
	CMP	BX, 0		; Done?
	JA	INNER
	CMP	AL, 0
	JA	OUTER
;
	POP	CX		; Return registers
	POP	BX
	POP	AX
	RET
DELAY		ENDP
; --------------------------------------------------------------------------
; CALL	NEXTCH		Returns character in next Brain position
;
; INPUT:
;	BRN_R		Coordinates of brain
;	BRN_C
; OUTPUT:
;	AL		Character at location
; --------------------------------------------------------------------------
NEXTCH		PROC
	PUSH	BX		; Save registers
	PUSH	DX
;
	MOV	DH, BRN_R	; Copy brain coordinates
	MOV	DL, BRN_C
;
; Find next coordinates according to direction
	CMP	BRN_VDIR, 0	; Going up or down?
	JNE	DOWN1
	DEC	DH		; up? decrease row
	JMP	LEFT1
DOWN1:	INC	DH		; down? increase row
LEFT1:	CMP	BRN_HDIR, 0	; Going left or right?
	JNE	RGHT1
	DEC	DL
	JMP	GETPOS
RGHT1:	INC	DL
; In the right place. Now, get character
GETPOS: CALL	SETCUR
	MOV	AH, 8		; Read character at pos
	MOV	BH, 0		; Set video page
	INT	10H
;
	POP	DX		; Return registers
	POP	BX
	RET
NEXTCH		ENDP
; --------------------------------------------------------------------------
; CALL	PRINTNUM		Prints a number from 0-999
;
;	BX	Number to print out
;	DH, DL	Row, column
; --------------------------------------------------------------------------
NUM	DW	?		; Used to manipulate number from BX since
;				  we will need BH and BL
;
PRINTNUM	PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
; Save value
	MOV	BH, 0		; Use all of BX
	MOV	NUM, BX
; Initialize color, num chars, position
	MOV	BL, 4FH			; White on red
	MOV	CX, 1			; 1 char at a time
; Print 100s value (by repetitive subtraction)
	MOV	AL, '0'
L100:	CMP	NUM, 100	; Can we subtract 100?
	JB	X100		; no? get out
	SUB	NUM, 100	; subtract!
	ADD	AL, 1		; add 1 to 100s total
	JMP	L100		; keep going
X100:	MOV	AH, AL		; AH stores AL value
	CMP	AL, '0'
	JNE	P100
	MOV	AL, ' '
P100:	CALL	PAINT
	MOV	AL, AH
	INC	DL
; Print 10s value
L10:	CMP	NUM, 10		; Can we subtract 10?
	JB	X10		; no? get out
	SUB	NUM, 10		; subtract!
	ADD	AL, 1		; add 1 to 10s total
	JMP	L10
X10:	MOV	AH, AL
	CMP	AL, '0'
	JNE	P10
	MOV	AL, ' '
P10:	CALL	PAINT		; Print the tens
	MOV	AL, AH
	INC	DL
; Print 1s value
	MOV	AX, '0'
	ADD	AX, NUM
	CALL	PAINT
;
	POP	DX		; Return registers
	POP	CX
	POP	BX
	POP	AX
	RET
PRINTNUM	ENDP
; --------------------------------------------------------------------------
; CALL	PRINTSTR	Prints a string
;
;	AH		If set to 0DDH, do "typing effect"
;	BL		Color
;	DH, DL		Row, column to start at
;	SI		Pointer to string
; --------------------------------------------------------------------------
;
PRINTSTR	PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
; Save original column in case we print multiple lines
	MOV	BH, DL
; Initialize offset counter, color, number of chars
	MOV	CX, 1		; Num chars
PRMSG:	MOV	AH, 1		; If character is pressed...
	INT	16H		; ... turn off "typing effect"
	JZ	PRMSG0
	MOV	EFF, 0		; Turns off EFF
	MOV	AH, 0		; Gets the key
	INT	16H		; and throws it outt
PRMSG0: MOV	AL, [SI]	; Get character
	CMP	AL, 0DDH	; Newline?
	JNE	PRMSG1		; ... if no, skip
	INC	SI		; Goto next character
	INC	DH		; Increase row
	MOV	DL, BH		; Go back to original column
	JMP	PRMSG		; ... and do next char
PRMSG1: CMP	EFF, 0FFH	; Do a delay?
	JNE	PRMSG2		; ... if no, skip
	CALL	DELAY		; Delay
PRMSG2: CALL	PAINT		; Paint the character
	INC	SI		; Next character
	INC	DL		; Increase column
	CMP	AL, 0FFH	; End of string?
	JNE	PRMSG
;
	POP	SI		; Return registers
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET
PRINTSTR	ENDP
; --------------------------------------------------------------------------
;  CALL PRINTRNG	Prints remaning distance
;
;	RNG_LFT		Distance remaining (for label)
; --------------------------------------------------------------------------
PRINTRNG	PROC
	PUSH	AX	; Save registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
; Divide RNG_LFT by RNG_DEC (we will print 0-5 spades)
	MOV	BL, RNG_DEC
	MOV	AH, 0
	MOV	AL, RNG_LFT
	DIV	BL
; Copy distance left
	MOV	AH, AL
; Initialize color, num chars, location
	MOV	BL, C_RNG
	MOV	CX, 1
	MOV	DH, 24
	MOV	DL, 72
; Now, print spades
	MOV	AL, 04H		; Spade character
	MOV	CH, 0
	MOV	CL, AH
	CALL	PAINT
; Print spaces (will be 5 minus # of spades)
	ADD	DL, AH		; offset column location by amt of spades
	MOV	AH, 5
	SUB	AH, CL
	XCHG	CL, AH
	MOV	AL, ' '
	CALL	PAINT
;
XPDIS:	POP	DX		; Return registers
	POP	CX
	POP	BX
	POP	AX
	RET
PRINTRNG	ENDP
; --------------------------------------------------------------------------
;	CALL	NOTE
;  Routine to play note on speaker
;
;	AX	      Frequency in Hz (32 - 32000)
;	DX	      Duration in units of 1/100 second
;
;  Note: a frequency of zero, means rest (silence) for the indicated
;  time, allowing this routine to be used simply as a timing delay.
; --------------------------------------------------------------------------
;
;  Definitions for timer gate control
CTRL	  EQU	61H	     ; timer gate control port
TIMR	  EQU	00000001B     ; bit to turn timer on
SPKR	  EQU	00000010B     ; bit to turn speaker on
;
;  Definitions of input/output ports to access timer chip
;
TCTL	  EQU	043H	      ; port for timer control
TCTR	  EQU	042H	      ; port for timer count values
;
;  Definitions of timer control values (to send to control port)
;
TSQW	  EQU	10110110B     ; timer 2, 2 bytes, sq wave, binary
LATCH	  EQU	10000000B     ; latch timer 2
;
;  Define 32 bit value used to set timer frequency
;
FRHI	  EQU	0012H	       ; timer frequency high (1193180 / 256)
FRLO	  EQU	34DCH	       ; timer low (1193180 mod 256)
;
NOTE	  PROC
      PUSH  AX		; save registers
      PUSH  BX
      PUSH  CX
      PUSH  DX
      PUSH  SI
; If sound is OFF, quit right away
	CMP	SOUND, 0
	JE	XNOTE
;
	MOV   BX,AX	   ; save frequency in BX
	MOV   CX,DX	   ; save duration in CX
;
;  We handle the rest (silence) case by using an arbitrary frequency to
;  program the clock so that the normal approach for getting the right
;  delay functions, but we will leave the speaker off in this case.
;
      MOV   SI,BX	   ; copy frequency to BX
      OR    BX,BX	   ; test zero frequency (rest)
      JNZ   NOT1	  ; jump if not
      MOV   BX,256	    ; else reset to arbitrary non-zero
;
;  Initialize timer and set desired frequency
;
NOT1: MOV   AL,TSQW	     ; set timer 2 in square wave mode
      OUT   TCTL,AL
      MOV   DX,FRHI	     ; set DX:AX = 1193180 decimal
      MOV   AX,FRLO	     ;	    = clock frequency
      DIV   BX		; divide by desired frequency
      OUT   TCTR,AL	     ; output low order of divisor
      MOV   AL,AH	   ; output high order of divisor
      OUT   TCTR,AL
;
;  Turn the timer on, and also the speaker (unless frequency 0 = rest)
;
      IN    AL,CTRL	     ; read current contents of control port
      OR    AL,TIMR	     ; turn timer on
      OR    SI,SI	   ; test zero frequency
      JZ    NOT2	  ; skip if so (leave speaker off)
      OR    AL,SPKR	     ; else turn speaker on as well
;
;  Compute number of clock cycles required at this frequency
;
NOT2: OUT   CTRL,AL	     ; rewrite control port
      XCHG  AX,BX	   ; frequency to AX
      MUL   CX		; frequency times secs/100 to DX:AX
      MOV   CX,100	    ; divide by 100 to get number of beats
      DIV   CX
      SHL   AX,1	  ; times 2 because two clocks/beat
      XCHG  AX,CX	   ; count of clock cycles to CX
;
;  Loop through clock cycles
;
NOT3: CALL  RCTR	  ; read initial count
;
;  Loop to wait for clock count to get reset. The count goes from the
;  value we set down to 0, and then is reset back to the set value
;
NOT4: MOV   DX,AX	   ; save previous count in DX
      CALL  RCTR	  ; read count again
      CMP   AX,DX	   ; compare new count : old count
      JB    NOT4	  ; loop if new count is lower
      LOOP  NOT3	  ; else reset, count down cycles
;
;  Wait is complete, so turn off clock and return
;
      IN    AL,CTRL	     ; read current contents of port
      AND   AL,0FFH-TIMR-SPKR ; reset timer/speaker control bits
      OUT   CTRL,AL	     ; rewrite control port
;
XNOTE: POP   SI		; restore registers
      POP   DX
      POP   CX
      POP   BX
      POP   AX
      RET		; return to caller
NOTE	  ENDP
; --------------------------------------------------------------------------
;	CALL	RCTR
;
;	Routine to read count, returns current timer 2 count in AX
; --------------------------------------------------------------------------
;
RCTR	  PROC
      MOV   AL,LATCH	  ; latch the counter
      OUT   TCTL,AL	     ; latch counter
      IN    AL,TCTR	     ; read lsb of count
      MOV   AH,AL
      IN    AL,TCTR	     ; read msb of count
      XCHG  AH,AL	   ; count is in AX
      RET		; return to caller
RCTR	  ENDP
;
; --------------------------------------------------------------------------
;  CALL OUTRO		Shows closing scene
;
; --------------------------------------------------------------------------
OUTRO		PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	DX
; Initialize colors and clear the screen
	MOV	BX, C_INTRO2	; Yellow on black
	CALL	CLS
; Print "Press any key to continue..."
	MOV	DH, 23
	MOV	DL, 50
	LEA	SI, S_OUTRO7
	CALL	PRINTSTR
; Now, print frames
	MOV	BX, C_INTRO1	; White on black
; First frame
	MOV	DX, 0		; Start at (0,0)
	LEA	SI, S_OUTRO1	; Load strip
	CALL	PRINTSTR
	MOV	AH, 0		; Wait for key to be pressed
	INT	16H
; Second frame
	MOV	DL, 26		; Now at (0, 26)
	LEA	SI, S_OUTRO2	; Load strip
	CALL	PRINTSTR
	MOV	AH, 0		; Wait for key to be pressed
	INT	16H
; Third frame
	MOV	DL, 52		; Now at (0,52)
	LEA	SI, S_OUTRO3	; Load strip
	CALL	PRINTSTR
	MOV	AH, 0		; Wait for key to be pressed
	INT	16H
; Fourth frame
	MOV	DH, 12		; Now at (12,0)
	MOV	DL, 0
	LEA	SI, S_OUTRO4	; Load strip
	CALL	PRINTSTR
	MOV	AH, 0		; Wait for key to be pressed
	INT	16H
; Fifth frame
	MOV	DL, 26		; Start at (12, 26)
	LEA	SI, S_OUTRO5	; Load strip
	CALL	PRINTSTR
	MOV	AH, 0		; Wait for key to be pressed
	INT	16H
; Sixth frame
	MOV	DL, 52		; Start at (12, 52)
	LEA	SI, S_OUTRO6	; Load strip
	CALL	PRINTSTR
	MOV	AH, 0		; Wait for key to be pressed
	INT	16H

;
	POP	DX		; Return registers
	POP	BX
	POP	AX
	RET
OUTRO		ENDP
;
; --------------------------------------------------------------------------
;  CALL LOADLEV		Draws a level
;
;	CURLEV		Level pointer
; --------------------------------------------------------------------------
;
LOADLEV		PROC
	PUSH	AX		; Save registers
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
; Get current level
	MOV	AX, 0
	MOV	AL, CURLEV	; Level stored at LEVS[(CURLEV - 1) *2)
	DEC	AL		; for instance, Level 3 is located at
	ADD	AL, AL		; WORD PTR LEVS[4]
	MOV	SI, AX
	MOV	SI, LEVS[SI]
; Clear level space
	MOV	AL, ' '		; Paint all spaces
	MOV	DH, 1		; Start from topleft corner
	MOV	DL, 8
	MOV	BL, 0		; Color scheme (black)
CLEV:	MOV	CX, 70		; 70 character width
	CALL	PAINT
	INC	DH		; Next row
	CMP	DH, 24		; at last row?
	JNE	CLEV
; Turn off "new level"
	MOV	NEWLEV, 0
; Print number of attempts
	MOV	DH, 24		; Row
	MOV	DL, 12		; Column
	MOV	BL, ATT		; Load number
	CALL	PRINTNUM
; Set maximum distance for lev
	MOV	AL, [SI]	; Get the max distance
	MOV	RNG_MAX, AL	; Store in both RNG_MAX and _LFT
	MOV	RNG_LFT, AL
; Set distance decrement (for RANGE label. Always RNG_MAX / 5)
	MOV	BH, 5
	MOV	AH, 0
	DIV	BH
	MOV	RNG_DEC, AL
; Print current level
	MOV	DH, 24		; Row
	MOV	DL, 40		; Column
	MOV	BL, CURLEV	; Color scheme
	CALL	PRINTNUM
; New block. Get characteristics.
NEWBLK: INC	SI
	MOV	AL, [SI]	; Block type
	CMP	AL, 0FFH
	JE	XLEV1
	INC	SI
	MOV	DH, [SI]	; Starting row
	INC	SI
	MOV	DL, [SI]	; Starting col
	INC	SI
	MOV	AH, [SI]	; Num of blocks
; Which kind of block?
	CMP	AL, 'H'
	JE	DRAWH
	CMP	AL, '>'
	JE	DRAWG
; Draw horizontal block
DRAWH:	MOV	AL, 'L'		; Start with left edge
	MOV	BL, 11H		; Blue
	MOV	CX, 1
	CALL	PAINT
	MOV	AL, 'H'		; Now, paint block
	MOV	BL, 77H		; Gray
	MOV	CL, AH
	SUB	CL, 2		; Length will not include 2 edges
	INC	DL		; Start one position off
	CALL	PAINT
	MOV	AL, 'R'		; Paint right edge
	MOV	BL, 11H		; Blue
	ADD	DL, CL		; Offset by length
	MOV	CX, 1		; 1 character
	CALL	PAINT
	JMP	NEWBLK
; Help a brotha jump!
XLEV1:	JMP	XLEV
; Now, draw the goal
; Start with top of goal
DRAWG:	MOV	AL, 'L'
	MOV	CX, 1		; 1 character
	MOV	BL, 22H		; Color scheme
	CALL	PAINT
	INC	DL		; Next column
	MOV	CX, 2		; 2 characters
	MOV	AL, 'H'
	CALL	PAINT
	DEC	DL
; Middle part of goal
	MOV	AL, '>'
GLOOP:	INC	DH
	MOV	BL, 0EEH
	MOV	CX, 2
	CALL	PAINT
	MOV	BL, 22H
	MOV	CX, 1
	ADD	DL, 2
	CALL	PAINT
	SUB	DL, 2
	DEC	AH
	JNZ	GLOOP
	INC	DH
; Bottom of goal
	MOV	AL, 'L'
	MOV	CX, 1
	MOV	BL, 22H
	CALL	PAINT
	MOV	AL, 'H'
	MOV	CX, 2
	INC	DL
	CALL	PAINT
	DEC	DL
	JMP	NEWBLK
;
XLEV:	POP	SI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET
LOADLEV		ENDP
; Some strings. Always end in 0FFH
; For Intro screen
EFF	DB	0			; Text "typing" effect. (0FFH = on)
S_INTRO DB	'It is 2048, the year of the Twelfth Bit.', 0DDH, 0DDH
	DB	'In a pitiful attempt to regain his former grandeur,', 0DDH
	DB	'one-time billionaire William Henry Gates III has', 0DDH
	DB	'stolen the cryogenically frozen brain of Steve Jobs,', 0DDH
	DB	'which contains the secrets of the ubiquitous Mac OS L', 0DDH
	DB	'operating system.', 0DDH, 0DDH
	DB	'In order to extract the information, Gates will need', 0DDH
	DB	'to deploy his Brain Ushering Gun (BUG) to transport', 0DDH
	DB	'Jobs', 027H, ' chilled cerebrum through '
	DB	'the underground tunnels', 0DDH
	DB	'connecting Apple Headquarters to his subterranean', 0DDH
	DB	'laboratory in Redmond, Washington. This will be no easy', 0DDH
	DB	'task, as the tunnel system will surely contain many ', 0DDH
	DB	'perilous (and oddly pixelated) obstacles along the way.', 0FFH
S_SKIP	DB	'PRESS ANY KEY TO', 0DDH, 'SKIP...', 0FFH
; For Menu screen
S_LOGO	DB	'______ _____ _      _     _ _____         _ '
	DB	'      ___  _____ _____', 0DDH
	DB	'| ___ \_   _| |    | |   ( )  ___|       | |'
	DB	'     / _ \/  ___|_   _|', 0DDH
	DB	'| |_/ / | | | |    | |   |/\ `--.        | |'
	DB	'    / /_\ \ `--.  | |', 0DDH
	DB	'| ___ \ | | | |    | |      `--. \       | |'
	DB	'    |  _  |`--. \ | |', 0DDH
	DB	'| |_/ /_| |_| |____| |____ /\__/ /       | |'
	DB	'____| | | /\__/ / | |', 0DDH
	DB	'\____/ \___/\_____/\_____/ \____/        \__'
	DB	'___/\_| |_|____/  \_/', 0DDH, 0DDH, 0DDH
	DB	'                ___ ___________ ', 0DDH
	DB	'               |_  |  _  | ___ \', 0DDH
	DB	'                 | | | | | |_/ /', 0DDH
	DB	'                 | | | | | ___ \', 0DDH
	DB	'             /\__/ | \_/ / |_/ /', 0DDH
	DB	'             \____/ \___/\____/ ', 0FFH
S_MENU	DB	'HOW TO PLAY', 0DDH, 0DDH, 'START GAME', 0DDH, 0DDH
	DB	'LOAD GAME', 0DDH, 0DDH, 'EXIT', 0FFH
S_ENTERN DB	'ENTER NAME:', 0DDH, '(8 character max)', 0FFH
S_ERR1	DB	'ERROR! Make sure you are not using illegal characters.', 0FFH
S_ERR2	DB	'ERROR! File not found. Make sure spelling is correct.', 0FFH
; For Game Instructions
S_INST1	DB	'This is the goal. You want to shoot', 0DDH
	DB	'Steve Jobs', 027H, ' brain here.' 0FFH
S_INST2 DB	'This is the BUG. You can move it using the', 0DDH
	DB	'UP or DOWN keys. To change the direction of', 0DDH
	DB	'the turret, use the LEFT and RIGHT keys.', 0FFH
S_INST3	DB	'When you are done aiming the BUG, you can ' 0DDH
	DB	'shoot by pressing SPACEBAR.                ', 0DDH
	DB	'                                          ', 0FFH
S_INST4	DB	'Once you have shot, the Range Meter will', 0DDH
	DB	'show you how much distance is left. If the', 0DDH
	DB	'meter reaches zero, you will need to try again.', 0FFH
S_INST5	DB	'If you', 027H, 'd like to turn the sound off, press the' 0DDH
	DB	'S key. Pressing S again will turn it back on.', 0FFH
S_INST6	DB	'If the graphics are too slow, press PAGE DOWN', 0DDH
	DB	'to decrease the delay speed. If they are' 0DDH
	DB	'too fast, PAGE UP will increase the delay.', 0FFH
; For Game screen
S_DELAY DB	'DELAY:', 0FFH
S_LEVEL DB	' -  LEVEL     -', 0FFH
S_RANGE	DB	'RANGE:', 0FFH
S_ATT	DB	'ATTEMPTS:', 0FFH
S_SOUND	DB	'SOUND:', 0FFH
S_OFF	DB	'OFF', 0FFH
S_ON	DB	'ON ', 0FFH
; For Closing Sequence
S_OUTRO7 DB	'PRESS ANY KEY TO CONTINUE...', 0FFH
S_OUTRO1 DB	'==========================', 0DDH
	DB	'|                        |', 0DDH
	DB	'|       8888888          |', 0DDH
	DB	'|      /       \         |', 0DDH
	DB	'|      | 0===0 |         |', 0DDH
	DB	'|      |   v   |         |', 0DDH
	DB	'|       \  -  /          |', 0DDH
	DB	'|        |   |           |', 0DDH
	DB	'|________________________|', 0DDH
	DB	'|    AT LAST... TIME TO  |', 0DDH
	DB	'|    RECLAIM THE WORLD!  |', 0DDH
	DB	'==========================', 0FFH
S_OUTRO2 DB	'==========================', 0DDH
	DB	'   LETS LOAD MY BRAIN    |', 0DDH
	DB	'   DECODER...            |', 0DDH
	DB	'_________________________|', 0DDH
	DB	'                         |', 0DDH
	DB	'     ----------------    |', 0DDH
	DB	'     |    Windows   |    |', 0DDH
	DB	'     |     Vista    |    |', 0DDH
	DB	'     |   LOADING... |    |', 0DDH
	DB	'     |______________|    |', 0DDH
	DB	'           |   |         |', 0DDH
	DB	'==========================', 0FFH
S_OUTRO3 DB	'============================', 0DDH
	DB	'     ----------------      |', 0DDH
	DB	'     |    Windows   |      |', 0DDH
	DB	'     |     Vista    |      |', 0DDH
	DB	'     |   LOADING... |      |', 0DDH
	DB	'     |______________|      |', 0DDH
	DB	'           |   |           |', 0DDH
	DB	'                           |', 0DDH
	DB	'___________________________|', 0DDH
	DB	'     ITLL JUST TAKE A      |', 0DDH
	DB	'     SEC... OK?            |', 0DDH
	DB	'============================', 0FFH
S_OUTRO4 DB	'|                        |', 0DDH
	DB	'|   ----------------     |', 0DDH
	DB	'|   |    SYSTEM     |    |', 0DDH
	DB	'|   |    ERROR!     |    |', 0DDH
	DB	'|   | TERMINATING.. |    |', 0DDH
	DB	'|   |______________ |    |', 0DDH
	DB	'|         |   |          |', 0DDH
	DB	'|________________________|', 0DDH
	DB	'|       !@!##!@~$        |', 0DDH
	DB	'|                        |', 0DDH
	DB	'==========================', 0FFH
S_OUTRO5 DB	'                         |', 0DDH
	DB	'         8888888         |', 0DDH
	DB	'        /       \        |', 0DDH
	DB	'        | 0===0 |        |', 0DDH
	DB	'        |   v   |        |', 0DDH
	DB	'         \  0  /         |', 0DDH
	DB	'          |   |          |', 0DDH
	DB	'_________________________|', 0DDH
	DB	'    I HATE WINDOWS..     |', 0DDH
	DB	'                         |', 0DDH
	DB	'==========================', 0FFH
S_OUTRO6 DB	'                           |', 0DDH
	DB	'                           |', 0DDH
	DB	'                           |', 0DDH
	DB	'                           |', 0DDH
	DB	'          THE END.         |', 0DDH
	DB	'                           |', 0DDH
	DB	'                           |', 0DDH
	DB	'                           |', 0DDH
	DB	'                           |', 0DDH
	DB	'                           |', 0DDH
	DB	'============================', 0FFH
;
; --------------------------------------------------------------------------
; The levels:
;
; Format is: <Type>, <Starting Row>, <Starting Col>, <Height/Width>
; Types:	H - Horizontal block
;		> - Goal
; --------------------------------------------------------------------------
LEVS	DW	9 DUP (?)		; Stores locations for levels 1-9
CURLEV	DB	1			; Begin with level 1
NEWLEV	DB	0
;
LVL1	DB	70			; Max distance for brain
	DB	'H', 10, 56, 16
	DB	'H', 20, 15, 30
	DB	'>', 1, 75, 6
	DB	0FFH
;
LVL2	DB	70			; Max distance for brain
	DB	'H', 8, 45, 5
	DB	'H', 8, 55, 5
	DB	'H', 13, 66, 7
	DB	'H', 16, 54, 7
	DB	'H', 19, 42, 7
	DB	'H', 15, 10, 25
	DB	'>', 5, 75, 6
	DB	0FFH
;
LVL3	DB	70			; Max distance for brain
	DB	'H', 12, 20, 15
	DB	'H', 14, 40, 15
	DB	'H', 15, 60, 10
	DB	'>', 16, 75, 6
	DB	0FFH
;
LVL4	DB	70			; Max distance for brain
	DB	'H', 4, 68, 5
	DB	'H', 8, 10, 8
	DB	'H', 8, 22, 8
	DB	'H', 8, 34, 8
	DB	'H', 8, 46, 8
	DB	'H', 8, 58, 8
	DB	'H', 16, 16, 8
	DB	'H', 16, 28, 8
	DB	'H', 16, 40, 8
	DB	'H', 16, 52, 8
	DB	'H', 16, 64, 8
	DB	'>', 6, 75, 4
	DB	0FFH
;
LVL5	DB	75			; Max distance for brain
	DB	'H', 8, 58, 6
	DB	'H', 6, 36, 6
	DB	'H', 12, 34, 10
	DB	'H', 18, 36, 6
	DB	'H', 14, 64, 6
	DB	'>', 1, 75, 5
	DB	0FFH
;
LVL6	DB	75			; Max distance for brain
	DB	'H', 8, 10, 33
	DB	'H', 8, 55, 15
	DB	'H', 13, 60, 15
	DB	'H', 15, 15, 10
	DB	'H', 15, 30, 10
	DB	'H', 20, 20, 10
	DB	'H', 20, 35, 10
	DB	'>', 1, 75, 6
	DB	0FFH
;
LVL7	DB	70			; Max distance for brain
	DB	'H', 12, 48, 7
	DB	'H', 13, 59, 6
	DB	'H', 14, 69, 3
	DB	'H', 20, 13, 6
	DB	'H', 16, 21, 6
	DB	'H', 10, 33, 6
	DB	'H', 6, 42, 6
	DB	'>', 16, 75, 6
	DB	0FFH
;
LVL8	DB	75			; Max distance for brain
	DB	'H', 4, 32, 6
	DB	'H', 5, 32, 6
	DB	'H', 9, 32, 6
	DB	'H', 10, 32, 6
	DB	'H', 4, 58, 6
	DB	'H', 5, 58, 6
	DB	'H', 9, 58, 6
	DB	'H', 10, 58, 6
	DB	'H', 11, 48, 6
	DB	'H', 12, 48, 6
	DB	'H', 17, 48, 6
	DB	'H', 18, 48, 6
	DB	'H', 11, 68, 6
	DB	'H', 12, 68, 6
	DB	'H', 17, 68, 6
	DB	'H', 18, 68, 6
	DB	'>', 3, 75, 4
	DB	0FFH
;
LVL9	DB	85			; Max distance for brain
	DB	'H', 3, 30, 15
	DB	'H', 3, 52, 6
	DB	'H', 4, 52, 6
	DB	'H', 5, 52, 6
	DB	'H', 6, 52, 6
	DB	'H', 7, 52, 6
	DB	'H', 8, 52, 6
	DB	'H', 9, 52, 6
	DB	'H', 10, 52, 6
	DB	'H', 11, 52, 6
	DB	'H', 12, 52, 6
	DB	'H', 8, 22, 6
	DB	'H', 9, 22, 6
	DB	'H', 10, 22, 6
	DB	'H', 11, 22, 6
	DB	'H', 12, 22, 6
	DB	'H', 13, 22, 6
	DB	'H', 14, 22, 6
	DB	'H', 15, 22, 6
	DB	'H', 16, 22, 6
	DB	'H', 16, 40, 30
	DB	'H', 20, 36, 30
	DB	'>', 17, 75, 5
	DB	0FFH
	END
