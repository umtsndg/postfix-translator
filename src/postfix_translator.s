.section .bss
input_buffer: .space 256            # Allocate 256 bytes for input buffer
output_buffer: .space 12            # Allocate 12 bytes for output buffer


.section .data
# string variables for constant values in the output
first_row_message: .ascii " 00000 000 00010 0010011\n"
second_row_message: .ascii " 00000 000 00001 0010011\n"
third_row_message: .ascii " 00010 00001 000 00001 0110011\n"
addition_message: .ascii "0000000"
subtraction_message: .ascii "0100000"
multiplication_message: .ascii "0000001"
xor_message: .ascii "0000100"
and_message: .ascii "0000111"
or_message: .ascii "0000110"

.section .text
.global _start

_start:
    # Read input from standard input
    mov $0, %eax                    # syscall number for sys_read
    mov $0, %edi                    # file descriptor 0 (stdin)
    lea input_buffer(%rip), %rsi    # pointer to the input buffer
    mov $256, %edx                  # maximum number of bytes to read
    syscall                         # perform the syscall

    lea input_buffer(%rip), %r8     #adress of the input buffer
    lea output_buffer(%rip), %r9    #adress of the output buffer

    # set the counters to zero
    mov $0, %rcx # register storing the current number
    mov $0, %r13 # register storing 0 if the current print operation is for first row, 1 if it is for second row
    mov $0, %r14 # register storing 0 if the last seen non space input is a digit, 1 if it is an operator

    jmp char_checker


# checks the characters in the input
char_checker:
    mov $0, %rbx
    mov (%r8), %bl

    cmp $'\n', %rbx
    je exit_program

    cmp $' ', %rbx
    je space

    cmp $'+', %rbx
    je decimal_to_binary

    cmp $'-', %rbx
    je decimal_to_binary

    cmp $'*', %rbx
    je decimal_to_binary

    cmp $'^', %rbx
    je decimal_to_binary

    cmp $'&', %rbx
    je decimal_to_binary

    cmp $'|', %rbx
    je decimal_to_binary

    jmp digit


# multiplies the last stored integer with 10 and adds the new digit
digit:
    mov $0, %r14 # sets the last seen non space input to a digit

    sub $'0', %rbx

    mov $10, %rax
    mul %rcx

    mov %rax, %rcx
    add %rbx, %rcx

    inc %r8
    jmp char_checker

space:
    cmp $0, %r14 # stores the last seen state(0 if digit, 1 operator)
    je space_after_digit
    
    jmp space_after_operator


# push the integer to the stack and resets the stored number
space_after_digit:
    push %rcx
    mov $0, %rcx

    inc %r8
    jmp char_checker

# resets rcx, stored number
space_after_operator:
    mov $0, %rcx
    inc %r8
    jmp char_checker


#outputs the popped value in binary form
decimal_to_binary:
    mov $1, %r14 # sets the last seen non space input to a operator

    pop %r10 # stores the last popped number
    mov $12, %r11 # sets the counter for division with 2 to 12
    mov %r10, %rcx

    cmp $0, %rcx
    ja negative
    jmp positive


# handles the negative numbers by adding 2^12 to them, which makes the number same as its 12 bit 2's complement
negative:
    
    add $4096, %rcx
    jmp positive

# divides the number wtih 2, 12 time and adds the carry to the output starting from the rigth
positive:
    cmp $0, %r11 # checks the counter
    je rest_of_the_row

    shr $1, %rcx # checks the carry
    jc one_bit

    jmp zero_bit


# adds character 1 to the output buffer starting from right side
one_bit:
    dec %r11
    mov %r9, %r12
    add %r11, %r12
    movb $'1',(%r12)

    jmp positive

# adds character 0 to the output buffer starting from right side
zero_bit:
    dec %r11
    mov %r9, %r12
    add %r11, %r12
    movb $'0',(%r12)

    jmp positive


# outputs binary value 
rest_of_the_row:
    lea output_buffer(%rip), %rsi
    mov $12, %rdx
    call print_func

    cmp $0, %r13 # checks the currently outputting row
    je first_row

    jmp second_row

# outputs the string after the binary for addi to the 2nd register
first_row:
    mov $first_row_message, %rsi
    mov $25, %rdx
    call print_func

    mov $1, %r13 # sets the currently printing row to second one
    mov %r10, %r15 # moves the first popped number to r15
    jmp decimal_to_binary

# outputs the string after the binary for addi to the 1nd register
second_row:
    mov $second_row_message, %rsi
    mov $25, %rdx
    call print_func

    mov $0, %r13# sets the currently printing row to first one
    jmp operators


operators:
    cmp $'+', %rbx
    je addition

    cmp $'-', %rbx
    je subtraction

    cmp $'*', %rbx
    je multiplication

    cmp $'^', %rbx
    je bitwise_xor

    cmp $'&', %rbx
    je bitwise_and

    cmp $'|', %rbx
    je bitwise_or


# adds the last two popped numbers then pushes the value and outputs func7 of the addition operation
addition:
    add %r15, %r10
    push %r10
    mov $addition_message, %rsi
    mov $7, %rdx
    call print_func

    jmp rest_of_the_third_row

# subtracts the last two popped numbers then pushes the value and outputs func7 of the subtraction operation
subtraction:
    sub %r15, %r10
    push %r10
    mov $subtraction_message,  %rsi
    mov $7, %rdx
    call print_func

    jmp rest_of_the_third_row

# multiplies the last two popped numbers then pushes the value and outputs func7 of the multiplication operation
multiplication:
    mov %r10, %rax
    mul %r15
    push %rax
    mov $multiplication_message,  %rsi
    mov $7, %rdx
    call print_func

    jmp rest_of_the_third_row

# bitwise xors the last two popped numbers then pushes the value and outputs func7 of the xor operation
bitwise_xor:
    xor %r15, %r10
    push %r10
    mov $xor_message,  %rsi
    mov $7, %rdx
    call print_func

    jmp rest_of_the_third_row

# bitwise ands the last two popped numbers then pushes the value and outputs func7 of the and operation
bitwise_and:
    and %r15, %r10
    push %r10
    mov $and_message,  %rsi
    mov $7, %rdx
    call print_func

    jmp rest_of_the_third_row

# bitwise ors the last two popped numbers then pushes the value and outputs func7 of the or operation
bitwise_or:
    or %r15, %r10
    push %r10
    mov $or_message,  %rsi
    mov $7, %rdx
    call print_func

    jmp rest_of_the_third_row


# outputs the string after the func7 for R-format where 1st and 2nd registers are source register and 1st register is destination register
rest_of_the_third_row:
    mov $third_row_message,  %rsi
    mov $31, %rdx
    call print_func

    inc %r8
    jmp char_checker



    



# prints the values in the rsi with the length in rdx and return
print_func:
    mov $1, %rax              # syscall number for sys_write
    mov $1, %edi              # file descriptor 1 (stdout)
    syscall

    mov $0, %rsi
    mov $0, %rdx
    ret

exit_program:
    # Exit the program
    mov $60, %rax               # syscall number for sys_exit
    xor %edi, %edi              # exit code 0
    syscall
