type
  ByteOrder*      = enum
  # byte order representation
    boLE          = 0x00
    boBE          = 0xff
  Integer*          = uint8|uint16|uint32|uint64|uint|int8|int16|int32|int64|int
  ArrayView*        = array[1,uint8]|array[2,uint8]|array[4,uint8]|array[8,uint8]
  Single*           = byte|char|uint8|int8


const
  hostBO = cast[uint8](uint16(0xff00)).ByteOrder
  wordSize* = pointer.sizeof


proc reorder*(val: var Integer): void {. gcsafe .} =
  type T = Integer
  when val.sizeof == 1:
    discard
  elif T.sizeof == 2:
    var buffer: array[2,uint8]
    copyMem(addr buffer[0],addr val, 2)
    val = buffer[1].T shl 0 or
          buffer[0].T shl 8
  elif T.sizeof == 4:
    var buffer: array[4,uint8]
    copyMem(addr buffer[0],addr val, 4)
    val = buffer[3].T shl 0 or
          buffer[2].T shl 8 or
          buffer[1].T shl 16 or
          buffer[0].T shl 24
  else:
    var buffer: array[8,uint8]
    copyMem(addr buffer[0],addr val, 8)
    val = buffer[7].T shl 0 or
          buffer[6].T shl 8 or
          buffer[5].T shl 16 or
          buffer[4].T shl 24 or
          buffer[3].T shl 32 or
          buffer[2].T shl 40 or
          buffer[1].T shl 48 or
          buffer[0].T shl 56

proc toView*(val: Integer): ArrayView  {. noSideEffect, gcsafe .} =
    when val.sizeof == 1:
      result = cast[array[1,uint8]](val)
    elif val.sizeof == 2:
      result = cast[array[2,uint8]](val)
    elif val.sizeof == 4:
      result = cast[array[4,uint8]](val)
    elif val.sizeof == 8:
      result = cast[array[8,uint8]](val)

proc fromView*(dst: var Integer, src: ArrayView): void {. gcsafe .} =
    when dst.sizeof == src.sizeof:
      when dst.sizeof == 1:
        dst = cast[uint8](src)
      elif dst.sizeof == 2:
        dst = cast[uint16](src)
      elif dst.sizeof == 4:
        dst = cast[uint32](src)
      elif dst.sizeof == 8:
        dst = cast[uint64](src)
    else:
      raise newException(ReraiseError, "destination and source have different sizes")


proc toInteger*(src: ArrayView): Integer {. noSideEffect, gcsafe .} =
      when src.sizeof == 1:
        result = cast[uint8](src)
      elif src.sizeof == 2:
        result = cast[uint16](src)
      elif src.sizeof == 4:
        result = cast[uint32](src)
      elif src.sizeof == 8:
        result = cast[uint64](src)


proc fromInteger*(dst: var ArrayView, src: Integer): void {. gcsafe .} =
    when dst.sizeof == src.sizeof:
      when dst.sizeof == 1:
        dst = cast[array[1,uint8]](src)
      elif dst.sizeof == 2:
        dst = cast[array[2,uint8]](src)
      elif dst.sizeof == 4:
        dst = cast[array[4,uint8]](src)
      elif dst.sizeof == 8:
        dst = cast[array[8,uint8]](src)
    else:
      raise newException(ReraiseError, "destination and source have different sizes")


proc bin*[T](src: T): seq[char] {. noSideEffect, gcsafe .} =
  result = newSeq[char](T.sizeof)
  copyMem(addr result[0], src.unsafeAddr, result.len)


proc fromBin*[T](dest: var T, src: openArray[char]): void {. gcsafe .} =
  copyMem(addr dest, src[0].unsafeAddr, src.len)


proc toEntity*[T](src: openArray[char]): T {. noSideEffect, gcsafe .} =
  copyMem(addr result, src[0].unsafeAddr, T.sizeof)

proc swap*[T](target: var T): void {. gcsafe .} =
    var 
      targetPtr = cast[uint](addr target)
      numWords = (T.sizeof / wordSize).int
    
    for i in 0..<numWords:
        reorder(cast[ptr uint64](targetPtr + (i * 8).uint)[])
        when T.sizeof mod wordSize != 0:
          let rest = wordSize - T.sizeof mod wordSize
          reorder(cast[ptr uint64](targetPtr + (numWords * 8).uint)[])
          moveMem(
            cast[pointer](targetPtr + ((numWords * 8).uint)),
            cast[pointer](targetPtr + (numWords * 8).uint  + rest.uint), wordSize)



proc hton*[T](val: var T): void {. gcsafe .} = 
  if hostBO == boLE:
    val.swap()

proc ntoh*[T](val: var T): void {. gcsafe .} =
  hton(val)