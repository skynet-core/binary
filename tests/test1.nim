# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import binary

type 
  TestType1 {. packed .} = object
    word: uint16
    bt:   uint8
    word2: uint16
    quad: uint

test "host to network tests":
  var 
    v1 = uint8(0xFF)
    v2 = uint16(0xFF00)
    v4 = uint32(0xFF00FF00)
    v8 = 0x01_00_00_FF_00_FA_FF_00'u64
  
  reorder(v1)
  assert v1 == uint8(0xFF)
  reorder(v2)
  assert v2 == uint16(0x00FF)
  reorder(v4)
  assert v4 == uint32(0x00FF00FF)
  let arr = v4.toView
  assert [255'u8,0,255,0] == arr
  reorder(v8)
  assert v8 == 0x00_FF_FA_00_FF_00_00_01'u64
  assert v8.toView == [1'u8, 0, 0, 255, 0, 250, 255, 0]
  assert v8 == toInteger([1'u8, 0, 0, 255, 0, 250, 255, 0])

test "test binary serialization":
  let tt = TestType1(word: 0xfeff, bt: 0x15, word2: 0x0ab0, quad: 0xff_01_02_03_04_ee_00_c0'u)
  let binData = tt.bin
  var 
    nt: TestType1
  nt.fromBin(binData)
  assert tt == nt
  var e = toEntity[TestType1](binData)
  assert tt == e
  assert tt.word2 == e.word2
  assert nt.word2 == tt.word2
  let before = nt
  nt.swap()
  nt.swap()
  assert before.bin == nt.bin