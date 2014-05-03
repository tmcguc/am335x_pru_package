
import socket
import time
import struct
import numpy

# address of the BeagleBone DMX
IP = "10.0.1.8"
PORT = 5009


buf_size = 4096
#data =[]

# can just us numpy.int16 to take care of 2's complement
#easily scan in every direction
dt = numpy.dtype('uint32')

def loop():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
    sock.bind(("",PORT))
    count = 0
    while True:
    
        data = sock.recv(buf_size)
        #Grab data from buff keep sign shift remaing data back print values
        X = numpy.frombuffer(data, dtype = dt, count = 1020, offset = 16)
        #typecast to keep sign
        Copy = numpy.int32(X << 14)
        #shift data back to proper space
        #now we have signed 18bit data represented as signed int32
        Z = Copy >> 14
        #data is always zero indexed
        print "data", count , " len", len(data), "X" , X[0], "Z", Z[4]

        count += 1




if __name__ == "__main__":
    loop()
    sock.close()

