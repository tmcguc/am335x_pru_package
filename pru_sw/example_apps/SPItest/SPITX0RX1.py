from mmap import mmap
import time, struct
from PYSPI import *

MCSPI1_offset = 0x481a0000
MCSPI1_size = 0xfff

MCSPI0_offset = 0x48030000
MCSPI0_size = 0xfff


CM_PER = 0x44E00000

CM_PER_SPI1_CLK_CTRL =  0x50
CM_PER_SPI0_CLK_CTRL =  0x4C



#TODO: put inside a dictionary or make a object for these offsets 
MCSPI_REVISION      = 0x000
MCSPI_SYSCONFIG     = 0x110
MCSPI_SYSSTATUS     = 0x114
MCSPI_IRQSTATUS     = 0x118
MCSPI_IRQENABLE     = 0x11c
MCSPI_WAKEUPENABLE  = 0x120
MCSPI_SYST          = 0x124
MCSPI_MODULCTRL     = 0x128

MCSPI_XFERLEVEL     = 0x17c
MCSPI_DAFTX         = 0x180   # DMA address aligned FIFO TX register
MCSPI_DAFRX         = 0x1a0   # DMA address aligned FIFO RX register

MCSPI_CH0CONF       = 0x12c
MCSPI_CH0STAT       = 0x130
MCSPI_CH0CTRL       = 0x134
MCSPI_TX0           = 0x138
MCSPI_RX0           = 0x13c

MCSPI_CH1CONF       = 0x140
MCSPI_CH1STAT       = 0x144
MCSPI_CH1CTRL       = 0x148
MCSPI_TX1           = 0x14c
MCSPI_RX1           = 0x150


spi_setup = SPI_SETUP()

reg = Reg_Helper()


f = open("/dev/mem", "r+b")

spimem = mmap(f.fileno(), MCSPI1_size, offset = MCSPI1_offset)
Cmem = mmap(f.fileno(), 0xfff, offset = CM_PER)


reg.setAndCheckReg(CM_PER_SPI1_CLK_CTRL, Cmem, 0x2, name = "CM_PER_SPI1_CLK_CTRL")

sys = reg.getReg(MCSPI_SYSCONFIG, spimem)
print"register value of MCSPI_SYSCONFIG:"
reg.printValue(sys)
reset = 0x1<<1
sysReset = sys | reset
reg.setReg(MCSPI_SYSCONFIG, spimem, sysReset)




check = True
count = 0
while(check):
    stat = reg.getReg(MCSPI_SYSSTATUS, spimem)
    count +=1 
    resetdone = 0x1 & stat
    if (resetdone == 0x1):
        check = False
print"register value of MCSPI_SYSSTATUS:"
print"Count:" + str(count)
reg.printValue(stat)


#check MCSPI is reset
#reg.waitTillSet(MCSPI_SYSSTATUS, spimem, bit = 0, value = 0x1, name = "MCspi1SYSstatus")





#setup modcontrol with default values
MODCONTROL = spi_setup.setMODCONTROL()
reg.setAndCheckReg(MCSPI_MODULCTRL, spimem, MODCONTROL, name = "MCSPI_MODULCTRL")


#set up the sysconfig register with defaults
SYSCONFIG = spi_setup.setSYSCONFIG()
reg.setAndCheckReg(MCSPI_SYSCONFIG, spimem, SYSCONFIG, name = "MCSPI_SYSCONFIG")


#get value of interupt register status
irq = reg.getReg(MCSPI_IRQSTATUS, spimem)
print"inital status of MCSPI_IRQSTATUS :"
reg.printValue(irq)


#clear interupt status bits write all ones
reg.setAndCheckReg(MCSPI_IRQSTATUS, spimem, 0xffffffff, name = "MCSPI_IRQSTATUS")


#set up interupts
IRQENABLE = spi_setup.setIRQENABLE()
reg.setAndCheckReg(MCSPI_IRQENABLE, spimem, IRQENABLE, name = "MCSPI_IRQENABLE")


#make sure channel is disabled
reg.setAndCheckReg(MCSPI_CH0CTRL, spimem, 0x00000000)


#set up channel configuration
CH_CONF = spi_setup.setCH_CONF(FFEW = 1, FORCE = 1, TURBO = 1, CLKD = 2, TRM = 2, WL = 0x11 )
reg.setAndCheckReg(MCSPI_CH0CONF, spimem, CH_CONF, name = "MCSPI_CH0CONF")

#setup transfer level for turbo mode
XFER = spi_setup.setXFERLEVEL(WCNT= 0x4)
reg.setAndCheckReg(MCSPI_XFERLEVEL, spimem, XFER, name ="XFERLevel")


#enable channel
reg.setAndCheckReg(MCSPI_CH0CTRL, spimem, 0x00000001, name = "enable CH")

#check if txs status bit is cleared
reg.waitTillSet(MCSPI_CH0STAT, spimem, bit = 1, value = 1, name = "MCSPI_CH0STAT TXS")


#send 6 values
for i in range(6):
    reg.setAndCheckReg(MCSPI_TX0, spimem, 0xfff29999, name ="MCSPI_TX0")

#reg.waitTillSet(MCSPI_CH0STAT, spimem, bit = 1, value = 0, name = "MCSPI_CH0STAT TXS")

#print value of tx register
tx = reg.getReg(MCSPI_TX0, spimem)
print "contents of TX0 register are after write and TXS set:"
reg.printValue(tx)

#print value of txs bit
txsSet = reg.getReg(MCSPI_CH0STAT, spimem)
print "TXS set:"
reg.printValue(txsSet)

#disbale the channel
reg.setAndCheckReg(MCSPI_CH0CTRL, spimem, 0x00000000)
