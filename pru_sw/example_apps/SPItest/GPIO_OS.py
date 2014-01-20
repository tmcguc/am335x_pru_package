from mmap import mmap
import time, struct
from PYSPI import *


GPIO2_OFFSET = 0x481ac000
CLEAR = 0x190
SET = 0x194

OS_0 = 2
OS_1 = 3
OS_2 = 5

reg = Reg_Helper()


f = open("/dev/mem", "r+b")


#Memory maping SPI1
gpio = mmap(f.fileno(), 0xfff, offset = GPIO2_OFFSET)

value = 1 << OS_0 | 1 << OS_1 | 1 << OS_2
reg.setReg(SET, gpio, value)


