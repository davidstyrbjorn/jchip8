chip8_cls :: inline (chip8: *CHIP8) {
  display_clear(*chip8.display);
}

chip8_ret :: inline (chip8: *CHIP8) {
  chip8.stack_pointer -= 1;
  chip8.PC = chip8.stack[chip8.stack_pointer];
}

chip8_jp_addr :: inline (chip8: *CHIP8, opcode: u16) {
  addr := opcode & 0x0FFF;
  chip8.PC = addr;
}

chip8_call_addr :: inline (chip8: *CHIP8, opcode: u16) {
  addr := opcode & 0x0FFF;
  chip8.stack[chip8.stack_pointer] = chip8.PC;
  chip8.stack_pointer += 1;
  chip8.PC = addr;
}

chip8_se_vx_byte :: inline (chip8: *CHIP8, opcode: u16) {
  v_index := (opcode & 0x0F00) >> 8; // Shift down the lowest nibble so it comes first in our u16
  byte := opcode & 0x00FF;
  if chip8.V[v_index] == byte {
    chip8.PC += 2; // Skip next instruction
  }
}

chip8_sen_vx_byte :: inline (chip8: *CHIP8, opcode: u16) {
  v_index := (opcode & 0x0F00) >> 8; 
  byte := opcode & 0x00FF;
  if chip8.V[v_index] != byte {
    chip8.PC += 2; // Skip next instruction
  }
}

chip8_se_vx_vy :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  vy := (opcode & 0x00F0) >> 4;
  if chip8.V[vx] == chip8.V[vy] {
    chip8.PC += 2;
  } 
}

chip8_ld_vx_byte :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8;
  byte := (opcode & 0x00FF).(u8);
  chip8.V[vx] = byte;
}

chip8_add_vx_byte :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8;
  byte := (opcode & 0x00FF).(u8);
  chip8.V[vx] += byte;
}

chip8_ld_vx_vy :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  vy := (opcode & 0x00F0) >> 4;
  chip8.V[vx] = chip8.V[vy];
}

chip8_or_vx_vy :: 