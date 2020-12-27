import sequtils

type
  ByteOrder*      = enum
  # byte order representation
    boLE          = 0x00
    boBE          = 0xff
  BitMask*        = enum
    # enums uses int64 in background so we pass bmEight as a first
    bmEight       = 0xFF_00_00_00_00_00_00_00'i64
    bmFirst       = 0xff'u8
    bmSecond      = 0xff_00'u16
    bmThird       = 0xff_00_00'u32
    bmFourth      = 0xFF_00_00_00'u32
    bmFifth       = 0xFF_00_00_00_00'u64
    bmSixth       = 0xFF_00_00_00_00_00'u64
    bmSeventh     = 0xFF_00_00_00_00_00_00'u64
  ByteShift*    = enum
    bsOne        = 8 * 1
    bsTwo        = 8 * 2
    bsThree      = 8 * 3
    bsFour       = 8 * 4
    bsFive       = 8 * 5
    bsSix        = 8 * 6
    bsSeven      = 8 * 7
    bsEight      = 8 * 8

  Integer*          = uint8|uint16|uint32|uint64|uint|int8|int16|int32|int64|int
  ArrayView*        = array[1,uint8]|array[2,uint8]|array[4,uint8]|array[8,uint8]
  Single*           = byte|char|uint8|int8


const
  val = uint16(0xff00)
  wordSize* = pointer.sizeof

proc hostByteOrder*(): ByteOrder {. noSideEffect, gcsafe .} = 
    result = (cast[array[2,uint8]](val))[0].ByteOrder


proc reorder*(val: var Integer): void =
  type T = Integer
  when val.sizeof == 1:
    discard
  elif T.sizeof == 2:
    val = val shr bsOne.T or
          val shl bsOne.T
  elif T.sizeof == 4:
    val = val shr bsThree.T or
          val shr bsOne.T and bmSecond.T or # 3 -> 2 mask 2
          val shl bsOne.T and bmThird.T or # 2 -> 3 mask 3
          val shl bsThree.T
  else:
    val = (val shr bsSeven.T) or                               # 8 -> 1
          (val shr bsFive.T and bmSecond.T) or       # 7 -> 2 mask 2nd
          (val shr bsThree.T and bmThird.T) or       # 6 -> 3 mask 3th
          (val shr bsOne.T  and bmFourth.T) or       # 5 -> 4 mask 4th   
          (val shl bsOne.T  and bmFifth.T) or
          (val shl bsThree.T and bmSixth.T) or
          (val shl bsFive.T and bmSeventh.T) or
          (val shl bsSeven.T)



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


proc fromBin*[T](dest: var T, src: openArray[char]): void =
  copyMem(addr dest, src[0].unsafeAddr, src.len)


proc toEntity*[T](src: openArray[char]): T =
  copyMem(addr result, src[0].unsafeAddr, T.sizeof)

proc swap*[T](target: var T): void =
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



proc hton*[T](val: var T): void = 
  if hostByteOrder() == boLE:
    val.swap()

proc ntoh*[T](val: var T): void =
  hton(val)