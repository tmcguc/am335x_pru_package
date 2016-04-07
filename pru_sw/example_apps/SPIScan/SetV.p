.origin 0
.entrypoint START
#include "SetV.hp"


START:
// Enable OCP master port
    LBCO r0, C4, 4, 4
    CLR r0, r0, 4
    SBCO r0, C4, 4, 4





    SETUP:




    // setAndCheckReg(CM_PER_SPI1_CLK_CTRL, Cmem, 0x2, name = "CM_PER_SPI1_CLK_CTRL")
    //enable clkspiref and clk
    // SPI1 is the master aka HighLander
    MOV addr, CM_PER_SPI1_CLK_CTRL
    MOV val, CM_PER_SPI1_CLK_EN
    SBBO val, addr, 0, 4

    //enable clk for SPI0
    MOV addr, CM_PER_SPI0_CLK_CTRL
    MOV val, CM_PER_SPI0_CLK_EN
    SBBO val, addr, 0, 4
   


    // reset spi1
    MOV addr, MCSPI1 | MCSPI_SYSCONFIG
    LBBO val, addr, 0, 4
    SET val.t1
    SBBO val, addr, 0, 4
//
////check if reset is done
CHECKRESET:
    MOV addr, MCSPI1 | MCSPI_SYSSTATUS
    LBBO val, addr, 0, 4
    QBBC CHECKRESET, val.t0


    // reset spi0
    MOV addr, MCSPI0 | MCSPI_SYSCONFIG
    LBBO val, addr, 0, 4
    SET val.t1
    SBBO val, addr, 0, 4
//
////check if reset is done
CHECKRESET2:
    MOV addr, MCSPI0 | MCSPI_SYSSTATUS
    LBBO val, addr, 0, 4
    QBBC CHECKRESET2, val.t0


// Need to initialize ADC always do this on power up first conversion


PASSVALUES:
LBCO V1, CONST_PRUDRAM, 0, 4

LBCO V2, CONST_PRUDRAM, 4, 4

LBCO CTRL, CONST_PRUDRAM, 8, 4


SETUPADCM:
    
    // setAndCheckReg(MCSPI_MODULCTRL, spimem, MODCONTROL, name = "MCSPI_MODULCTRL")
    MOV addr, MCSPI1 |  MCSPI_MODULCTRL
    MOV val, MODCONTROL
    SBBO val, addr , 0, 4

    MOV  addr, MCSPI1 |  MCSPI_SYSCONFIG
    MOV  val, ADC_SYSCONFIG
    SBBO val, addr, 0, 4

    //reset interrupt status bits write all ones
    MOV addr, MCSPI1 |  MCSPI_IRQSTATUS
    MOV val, RESET_IRQ_STAT 
    SBBO val, addr, 0, 4

    //enable interupts for ADCs
    MOV addr, MCSPI1 | MCSPI_IRQENABLE
    MOV val, ADC_IRQENABLE
    SBBO val, addr, 0, 4
    
    //disable channel
    MOV addr, MCSPI1 |  MCSPI_CH0CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4

    // configure the channel 
    MOV addr, MCSPI1 |  MCSPI_CH0CONF     
    MOV val, ADC_MASTER_CONF
    SBBO val, addr, 0, 4


    //TODO XFER level will be determined from passed values
    // set xfer level
    MOV addr, MCSPI1 | MCSPI_XFERLEVEL
    MOV val, ADC_MASTER_XFER
    SBBO val, addr, 0, 4


SETUPDAC:
    

    //disable channel
    MOV addr, MCSPI1 |  MCSPI_CH1CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4

    // configure the channel 
    MOV addr, MCSPI1 |  MCSPI_CH1CONF     
    MOV val, DAC_MASTER_CONF
    SBBO val, addr, 0, 4
    
    //MOV V1, Start

    //QBBC CHECKTXSA, val.t1


    JMP DACUPDATE          // write out values to DACs
RDACUPDATE:


DONE:

    MOV R31.b0, PRU0_ARM_INTERRUPT+16

HALT

//Do something ???




//*=============================================================
//*This is where we are defining the DAC functionality !!!!
//*=============================================================



DACUPDATE:
    JMP ENABLEDAC          // Enable the DAC SPI channels TODO: need to write seperate ENABLE DAC 
RENABLEDAC:
    MOV DACC, INIT_DACC    //Change from A to C for seting up IV
    MOV DACD, INIT_DACD     //change from B to D for setting up IV
    OR DACC, V1.w0, DACC    // This takes the position Fx and adds the prefix for the DAC to go to DACC 
    OR DACD, V2.w0, DACD    // Same thing for DACD

CHECKT0:
    QBBS SETDACC, CTRL.t0 // See if we should write out DACC
    JMP CHECKT1           // Go to Check T1   

SETDACC:
    MOV addr, MCSPI1 | MCSPI_TX1     //TODO: make sure this is going to the right peripheral Should be MCSPI_TX1
    SBBO DACC, addr,0,4     //send out the data to DACC Yo

CHECKTXSA:
    MOV addr, MCSPI1 |  MCSPI_CH1STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXSA, val.t1

CHECKT1:
    QBBS SETDACD, CTRL.t1 //  check to see if we load DACD value
    JMP LOADDAC             // skip ahead to LOADDAC


SETDACD:
    MOV addr, MCSPI1 | MCSPI_TX1     //TODO: make sure this is going to the right peripheral Should be MCSPI_TX1
    SBBO DACD, addr,0,4     //send out the data to DACB Yo

CHECKTXSB:
    MOV addr, MCSPI1 |  MCSPI_CH1STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXSB, val.t1


    JMP LOADDAC            //
RLOADDAC:
    JMP DISABLEDAC         //
RDISABLEDAC:
    JMP RDACUPDATE


LOADDAC:
    JMP DELAY
RDELAY:
    MOV val, 0xac           // need a dealy of 1.7 us before we take pulse LDAC  low
DELAYLOADDAC:
    SUB val, val, 1
    QBNE DELAYLOADDAC , val , 0
    SET r30.t14             //MOV r30, 1 << 14  go high make sure output is high
    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
    SET r30.t14             //MOV r30, 1 << 14  go high make sure output is high
    JMP RLOADDAC               


ENABLEDAC:
    MOV addr, MCSPI1 |  MCSPI_CH1CTRL
    MOV val, EN_CH
    SBBO val, addr, 0, 4
    /// Took this from CHECKTXSDAC
CHECKTXSDAC:
    MOV addr, MCSPI1 |  MCSPI_CH1STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXSDAC, val.t1
    JMP RENABLEDAC


DISABLEDAC:
    MOV addr, MCSPI1 | MCSPI_CH1CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4
    JMP RDISABLEDAC

//*=======================================================
//* DELAY Routines
//*=======================================================


// Fixed Delay before loading values from register into DAC
DELAY:
    MOV r24, 0x96  //Test to delay LDAC until CS goes high
DELAY0:
    SUB r24, r24, 1
    QBNE DELAY0 , r24, 0
    JMP RDELAY


