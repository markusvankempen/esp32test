# Berry script driver - mvk

class TFLUNA : Driver

 var wire
 var distance
 var strength
 var temperature
 var dists
 var distc
 var version

 def init()
  self.wire = tasmota.wire_scan(0x20,58)
  self.dists=0
  self.distc=0  
  if self.wire
   print('TFLuna detected on bus '+str(self.wire.bus))
  end
 end 
 
 def read_distance()
 #Firmware version
  self.wire.write_bytes(0x20,0x5A,bytes('04015F'))
  tasmota.delay(2)
  var f= self.wire.read_bytes(0x20,0,7)

  if f.get(0,1)!=90  #which 5A
   print('TFMini pro not ready FW')
   print(f)
   return nil 
  end 

   self.version= f.get(5,1)  +f.get(4,1)  + f.get(3,1) 
  # self.version[ 1] = f.get(5,1)
  # self.version[ 2] = f[3];

#set frequence
#  self.wire.write_bytes(0x20,0x5A,bytes('06036400C7'))
#  tasmota.delay(1)
#  fr=tfmini.read_bytes(0x20,0,6)
#  print(fr.get(5,1)) == 199
#  print(tfmini.read_bytes(0x20,0,6))

#SEt Centimeter Format
#5A >05 >00 >01 >60 
self.wire.write_bytes(0x20,0x5A,bytes('05000160'))
tasmota.delay(2)
var b=self.wire.read_bytes(0x20,0,9)
  if b.get(0,1)!=89  #which 0x59
   print('TFMini pro not ready reading data frame')
   return nil 
  end 

  self.distance = b[ 2] + ( b[ 3] << 8)
  self.strength= b[ 4] + ( b[ 5] << 8)
  self.temperature= b[ 6] + ( b[ 7] << 8)

  #if self.strength<100 || self.strength>30000
  # print('TFLuna bad conditions')  
  #else
  # self.distc+=1
  # self.dists+=self.distance
  #end
  return self.distance
 end

 def json_append()
  if !self.wire return nil end  # I2C error
 import mqtt
 import string
  var distance = self.distance # int(self.dists/self.distc)
  var msg = string.format(",\"TFLuna\":{\"distance\":%i}",distance)
  tasmota.response_append(msg)
  self.dists=0
  self.distc=0  
 end

 def every_second() 
  if !self.wire return nil end # I2C error
  self.read_distance()
 end

 def every_100ms()
  if !self.wire return nil end # I2C error
   import mqtt
 import string
  self.read_distance()
   var distance = self.distance # int(self.dists/self.distc)
  var msg = string.format("{\"distance\":%i}",distance)
  mqtt.publish("tele/evdtestmvk/TFLuna",msg)
 end



 def web_sensor()
  if !self.wire return nil end # I2C error
  import string
  var msg = string.format(
      "{s}TFLuna Version: {m}%.0f {e}"..
      "{s}TFLuna Distance: {m}%.0f cm{e}"..
      "{s}TFLuna Strenght: {m}%.0f {e}"..
      "{s}TFLuna Temperatur: {m}%.2f °C{e}", 
      self.version,self.distance,self.strength,self.temperature)
  tasmota.web_send_decimal(msg)
 end
 

  
end
tfluna = TFLUNA()
tasmota.add_driver(tfluna)
