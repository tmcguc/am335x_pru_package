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


#Memory maping SPI1
spimem = mmap(f.fileno(), MCSPI1_size, offset = MCSPI1_offset)
Cmem = mmap(f.fileno(), 0xfff, offset = CM_PER)

#Memory mapping SPI0
spimem0 = mmap(f.fileno(), MCSPI0_size, offset = MCSPI0_offset)





for i in range(8):
    #Check value for RX register of SPI
    data = reg.getReg(MCSPI_DAFRX, spimem0)
    data = data & 0x3ffff 
    ## TODO: this is needed to get rid of data from previous call  data in FIFO includes previous 16 LSB from last
    ## write into FIFO data is not padded.  
    print "RX SLave data is"
    reg.printValue(data)



