ORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

ACIA_DATA   = $5000                    ; If ACIA_CTRL Bit 7 is low, RW Data, if ACIA_CTRL Bit 7 is high, First 8 Bits for baud
ACIA_BAUD   = $5001                    ; If ACIA_CTRL Bit 7 is low, Interrupt Register, if ACIA_CTRL Bit 7 is high, Last 8 Bits for baud
ACIA_FIFO   = $5002                    ; FIFO Control Register
ACIA_CTRL   = $5003
ACIA_MCTRL	= $5004
ACIA_STATUS = $5005

E  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

reset:
  ldx #$ff
  txs

  ;init of UART
  lda #%10000011  ;set 8-N-1 and divisor latch active
  sta ACIA_CTRL

  ;set BAUD Rate 19200 with 1.8432MHz Osz. and Divisor 6
  lda #%00000110  ;load 6 in LSB
  sta ACIA_DATA   ;$5000
  lda #%00000000  ;load 0 in MSB
  sta ACIA_BAUD   ;$5001

  lda #%00000011  ;set 8-N-1 and divisor latch inactive
  sta ACIA_CTRL

  lda #%00000000  ;disable all interrupts
  sta ACIA_BAUD

  lda #%00000000  ;disable FIFO
  sta ACIA_FIFO

  lda #%00000000  ;disable Modem Control
  sta ACIA_MCTRL





  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA

  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #$00000001 ; Clear display
  jsr lcd_instruction



  ldx #0
send_msg:
  lda message,x
  beq done
  jsr send_char
  inx
  jmp send_msg
done:


rx_wait:
  lda ACIA_STATUS
  bit #%00000010
  bne overrun
  clc

  bit #%00001000
  bne framing
  clc

  bit #%00010000
  bne break
  clc

  and #%00000001
  beq rx_wait


  lda ACIA_DATA
  jsr send_char
  jmp rx_wait

overrun:
  pha
  lda #$4F
  sta print_char
  pla
  clc
	rts

framing:
  pha
  lda #$46
  sta print_char
  pla
  clc
	rts

break:
  pha
  lda #$42
  sta print_char
  pla
  clc
	rts

message: .asciiz "UART Test"



send_char:
  pha
tx_wait:
  lda ACIA_STATUS ;check tx buffer status, if empty = 1
  and #%01000000        ; is bit 7 of the register
  beq tx_wait
  pla
  sta ACIA_DATA
  rts

send_char_delay:
  pha
  lda #$ff
tx_wait:
  cmp #0
  bne tx_wait
  pla
  sta ACIA_DATA
  rts



lcd_wait:
  pha
  lda #%00000000  ; Port B is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  and #%10000000
  bne lcdbusy

  lda #RW
  sta PORTA
  lda #%11111111  ; Port B is output
  sta DDRB
  pla
  rts

lcd_instruction:
  jsr lcd_wait
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  rts

print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts


  .org $fffc
  .word reset
  .word $0000