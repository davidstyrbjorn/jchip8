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

chip8_or_vx_vy :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  vy := (opcode & 0x00F0) >> 4;
  chip8.V[vx] |= chip8.V[vy];
} 

chip8_and_vx_vy :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  vy := (opcode & 0x00F0) >> 4;
  chip8.V[vx] &= chip8.V[vy];
}

chip8_xor_vx_vy :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  vy := (opcode & 0x00F0) >> 4;
  chip8.V[vx] ^= chip8.V[vy];
}

chip8_add_vx_vy :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  vy := (opcode & 0x00F0) >> 4;
  sum: u16 = chip8.V[vx] + chip8.V[vy];
  chip8.V[vx] = cast(u8)(sum & 0xFF00);
  // Set the carry flag, in register 0xF
  if sum > 255 {
    chip8.V[0xF] = 1; 
  } else {
    chip8.V[0xF] = 0;
  }
}

chip8_sub_vx_vy :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  vy := (opcode & 0x00F0) >> 4;
  chip8.V[vx] -= chip8.V[vy];
  // Set the borrow flag
  if chip8.V[vx] > chip8.V[vy] {
    chip8.V[0xF] = 1;
  } else {
    chip8.V[0xF] = 1;
  }
}

chip8_shr_vx :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  // Save LSB in vF
  chip8.V[0xF] = (chip8.V[vx] & 0x1);
  chip8.V[vx] >>= 1;
}

chip8_subn_vx_vy :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  vy := (opcode & 0x00F0) >> 4;
  chip8.V[vx] = chip8.V[vy] - chip8.V[vx];
  // Set the borrow flag
  if chip8.V[vy] > chip8.V[vx] {
    chip8.V[0xF] = 1;
  } else {
    chip8.V[0xF] = 1;
  }
}

chip8_shl_vx :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  // Save MSB in vF
  chip8.V[0xF] = (chip8.V[vx] & 0x80) >> 7;
  chip8.V[vx] <<= 1;
}

chip8_sne_vx_vy :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  vy := (opcode & 0x00F0) >> 4;
  if chip8.V[vx] != chip8.V[vy] {
    chip8.PC += 2;
  }
}

chip8_ld_i_addr :: inline (chip8: *CHIP8, opcode: u16) {
  addr := opcode & 0x0FFF; // Take the lowest 3 nibbles (12 bytes)
  chip8.I = addr;
}

chip8_jp_v0_addr :: inline (chip8: *CHIP8, opcode: u16) {
  addr := opcode & 0x0FFF; 
  chip8.PC += addr + chip8.V[0];
}


chip8_rnd_vx_byte :: inline (chip8: *CHIP8, opcode: u16) {
  random_byte :: () -> u8 {
    return cast(u8)(random_get() % 255);
  }
  vx := (opcode & 0x0F00) >> 8; 
  kk := cast(u8)(opcode & 0x00FF);
  chip8.V[vx] = random_byte() & kk;
}

chip8_drw_vx_vy_nibble :: inline (chip8: *CHIP8, opcode: u16) {
  vx := (opcode & 0x0F00) >> 8; 
  vy := (opcode & 0x00F0) >> 4;
  height := opcode & 0x000f;
  
  pos_x := chip8.V[vx] % DP_WIDTH;
  pos_y := chip8.V[vy] % DP_HEIGHT;

  chip8.V[0xF] = 0; // collision = false

  for row : 0..height-1 {
    sprite_byte := chip8.memory[chip8.I + row];
    for col : 0..7 {
      
    }
  }
}