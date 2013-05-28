.origin 0
.entrypoint START

#define PRU0_ARM_INTERRUPT 19
#define AM33XX

#define GPIO1 0x4804c000
#define GPIO_CLEARDATAOUT 0x190
#define GPIO_SETDATAOUT 0x194

#define MCSPI0 0x48030000
#define MCSPI1 0x481a0000


// Cn is the constants table for spi0 it is c6 address of 0x4803_0000
// c16 is for spi10x481a_0000

#define MCSPI_REVISION 0x000
#define MCSPI_SYSCONFIG 0x110
#define MCSPI_SYSSTATUS 0x114
#define MCSPI_IRQSTATUS 0x118
#define MCSPI_IRQENABLE 0x11c
#define MCSPI_SYST 0x124
#define MCSPI_MODULCTRL 0x128

#define MCSPI_XFERLEVEL 0x17c
#define MCSPI_DAFTX 0x180   // DMA address aligned FIFO TX register
#define MCSPI_DAFRX 0x1a0   // DMA address aligned FIFO RX register

#define MCSPI_CH0CONF 0x12c
#define MCSPI_CH0STAT 0x130
#define MCSPI_CH0CTRL 0x134
#define MCSPI_TX0 0x138
#define MCSPI_RX0 0x13c

#define MCSPI_CH1CONF 0x140
#define MCSPI_CH1STAT 0x144
#define MCSPI_CH1CTRL 0x148
#define MCSPI_TX1 0x14c
#define MCSPI_RX1 0x150






START:
// clear that bit
    LBCO r0, C4, 4, 4
    CLR r0, r0, 4
    SBCO r0, C4, 4, 4

    MOV r1, 100
// 


SETUP:




    //enable clkspiref and clk
    MOV r12, 0x44e00050
    LBBO r13, r12, 0, 4
    SET r13, 1
    SBBO r13, r12, 0, 4


    MOV r14, MCSPI1 | MCSPI_SYSCONFIG
    LBBO r15, r14, 0, 4
    SET r15, 1
    SBBO r15, r14, 0, 4


CHECKRESET:
    MOV r16, MCSPI1 | MCSPI_SYSSTATUS
    LBBO r17, r16, 0, 4
    QBBC CHECKRESET, r17.t0


    // for test no need to change modulctrl

    // settup sysconfig  for clocks and idle mode
    MOV  r18, 0x3<<8 |0x1
    SBBO r18, r14, 0, 4
    





   
    //reset interrupt status bits write all ones

    MOV r4, 0x960
    MOV r5, MCSPI1 | MCSPI_SYST
    SBBO r4, r5, 0, 4
    
    // transmit only| spi word is 24 bits| clock is dived by 2 
    MOV r6, 0x2<<12 | 0x17<<7 | 0x1<<2
    MOV r7, MCSPI1 | MCSPI_CH0CONF     
    SBBO r6, r7, 0, 4


BLINK:
    MOV r2, 7<<22
    MOV r3, GPIO1 | GPIO_SETDATAOUT
    SBBO r2, r3, 0, 4

    //enable channel
    MOV r8, MCSPI1 | MCSPI_CH0CTRL
    MOV r11, 0x1
    SBBO r11, r8, 0, 4


    //write all ones to spi tx register
    MOV r9, 0x00ffffff
    MOV r10 , MCSPI1 | MCSPI_TX0
    SBBO r9, r10,0,4


    MOV r0, 0x00f00000
DELAY:
    SUB r0, r0, 1
    QBNE DELAY, r0, 0

    //spi reset enable
    MOV r11, 0x0
    SBBO r11, r8, 0, 4
    //CLR r8.t0
    
    MOV r2, 7<<22
    MOV r3, GPIO1 | GPIO_CLEARDATAOUT
    SBBO r2, r3, 0, 4

    MOV r0, 0x00f00000
DELAY2:
    SUB r0, r0, 1
    QBNE DELAY2, r0, 0

    SUB r1, r1, 1
    QBNE BLINK, r1, 0








//#ifdef AM33XX
    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16
//#else
//    MOV R31.b0, PRU0_ARM_INTERRUPT
//#endif

HALT
