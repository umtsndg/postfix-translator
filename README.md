A GNU-Assembly code that translates a postfix expression into RISC-V 32-bit Machine Language instructions. 

Can be compiled and run with: 

as -o postfix_translator.o src/postfix_translator.s
ld -o postfix_translator postfix_translator.o
./postfix_translator
