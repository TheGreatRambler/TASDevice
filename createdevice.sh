SERIAL="$(grep Serial /proc/cpuinfo | sed 's/Serial\s*: 0000\(\w*\)/\1/')"
MAC="$(echo ${SERIAL} | sed 's/\(\w\w\)/:\1/g' | cut -b 2-)"
MAC_HOST="12$(echo ${MAC} | cut -b 3-)"
MAC_DEV="02$(echo ${MAC} | cut -b 3-)"

# Create gadget
mkdir /sys/kernel/config/usb_gadget/tasdevice
cd /sys/kernel/config/usb_gadget/tasdevice

# Add basic information
echo 0x0100 > bcdDevice # Version 1.0.0
echo 0x0200 > bcdUSB # USB 2.0
echo 0x02 > bDeviceClass
echo 0x00 > bDeviceProtocol
echo 0x00 > bDeviceSubClass
echo 0x08 > bMaxPacketSize0
echo 0x3066 > bcdDevice
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x1d6b > idVendor # Linux Foundation

# Create English locale
mkdir strings/0x409

echo "TheGreatRambler" > strings/0x409/manufacturer
echo "TASDevice" > strings/0x409/product
echo "0123456789" > strings/0x409/serialnumber

# Create HID function
mkdir functions/hid.usb0    # HID
mkdir functions/rndis.usb0  # network

echo 1 > functions/hid.usb0/protocol
echo 8 > functions/hid.usb0/report_length # 8-byte reports
echo 1 > functions/hid.usb0/subclass

# Write report descriptor
echo "05010906a101050719e029e71502750895018101750025017501950881019503050819012903910275019505910175089506150026ff00050719002aff008100c0" | xxd -r -ps > functions/hid.usb0/report_desc

# Write network functions
echo RNDIS   > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo 5162001 > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id
echo $MAC_HOST > functions/rndis.usb0/host_addr
echo $MAC_DEV > functions/rndis.usb0/dev_addr

# Create configuration
mkdir configs/c.1
mkdir configs/c.1/strings/0x409

echo 0x80 > configs/c.1/bmAttributes
echo 200 > configs/c.1/MaxPower # 200 mA
echo "Keyboard/RNDIS configuration" > configs/c.1/strings/0x409/configuration

# Link network function to configuration
ln -s functions/rndis.usb0 configs/c.1/

# OS descriptors
echo 1       > os_desc/use
echo 0xcd    > os_desc/b_vendor_code
echo MSFT100 > os_desc/qw_sign

ln -s configs/c.1 os_desc

# Enable gadget
echo "20980000.usb" > UDC

sleep 5

echo "" > UDC

# Link HID function to configuration again
ln -s functions/hid.usb0 configs/c.1

# Resets device class
echo "0x00" > bDeviceClass

# Reattach
echo "20980000.usb" > UDC

ifconfig usb0 up 10.0.99.1
