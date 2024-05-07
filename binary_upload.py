import serial
import time

# Open serial connection to Arduino
arduino = serial.Serial('/dev/cu.usbserial-11110', 57600)  # Adjust device path and baud rate as necessary
time.sleep(2)  # Allow time for Arduino to reset

# Define the path to the binary file
binary_file_path = 'a.out'  # Adjust the file path as necessary

# Read binary file
with open(binary_file_path, 'rb') as file:
    binary_data = file.read()

# Send binary data to Arduino
address = 0
time.sleep(2)
for byte in binary_data:
    print(hex(address))
    #print (byte.to_bytes(1, 'big'))
    #print(hex(byte))
    arduino.write(byte.to_bytes(1, 'big'))  # Send data byte
    arduino.write(address.to_bytes(2, 'big'))  # Send address byte

    time.sleep(0.011)  # Adjust delay as necessary
    address += 1

time.sleep(1)
# Close serial connection
arduino.close()
