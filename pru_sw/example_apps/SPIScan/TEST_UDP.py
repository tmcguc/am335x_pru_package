################################################################################
# dmxController.py
# ----------------
# 
# An example script that cycles through each DMX channel, turning each fully on
# one at a time
################################################################################

import socket
import time
import struct

# address of the BeagleBone DMX
IP = "10.0.1.8"
PORT = 9930

# number of DMX channels
CHANNELS = 4

# how many seconds to wait between sending a DMX update
DELAY = 0.5

def constructPayload():
    Sx = 0x8000
    Sy = 0x8000
    sdx = 0x0000
    sdy = 0x0040
    dx = 0x0040
    dy = 0x0000
    pF = 0x3ff
    sF = 0x3ff
    samp = 0x1
    CH = 0x2
    DVAR = 0x1
    res = "%8x" %Sx	
    res += "%8x"%Sy
    res += "%8x"%sdx
    res += "%8x"%sdy
    res += "%8x"%dx
    res += "%8x"%dy
    res += "%8x"%pF
    res += "%8x"%sF
    res += "%8x"%samp
    res += "%8x"%CH
    res += "%8x"%DVAR
    return res

def loop():
  sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
  sock.connect((IP, PORT))

  channel = 0
  #while True:
  payload = constructPayload()
  print payload
  sock.send(payload)
  #time.sleep(DELAY)

if __name__ == "__main__":
  loop()
  #sock.close()

