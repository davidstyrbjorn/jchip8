/*
* This is an CHIP-8 "Emulator"
* But to be accurate its not actually emulator
* Since we're not emulating any actual hardware it's more accurately 
* a CHIP-8 "Interpreter" :) 
* This is my first emulator attempt and its my 3rd-ish program in Jai so be careful 
* if you're looking at this code as any type of example/inspiration!
*/

/*
* CHIP-8 has the following components: 
* - Memory: direct access up to 4 kilobytes of RAM
* - Display: 64 x 32 pixels monochrome 
* - A program counter "PC", pointing to the current instruction in memory
* - One 16-bit index register called "I" (capital i)
* - A stack for 16-bit addresses, used to call subroutines and return from them
* - An 8-bit delay timer, which is decremented at a rate of 60 times per second until it reaches 0
* - An 8-bit sound timer which functions like the delay timer, gives of a beeping sound as long as it's > 0
* - 16 8-bit general purpose variable registers numbered 0 - F, called V0 to VF
*     - VF is also used as a flag register, many instructions will set it to either 1 or 0 based on some rule
*     - for example used as a carry flag
*
*
* The index register "I", program counter "PC" and stack entries are all 16 bits long, so they can address beyond 4kb of memory
* In practice, no CHIP-8 game do this, in the old days most machines running CHIP-8 had less than 4kB of RAM anyway
*
*/

FONT :: u8.[
  0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
  0x20, 0x60, 0x20, 0x20, 0x70, // 1
  0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
  0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
  0x90, 0x90, 0xF0, 0x10, 0x10, // 4
  0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
  0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
  0xF0, 0x10, 0x20, 0x40, 0x40, // 7
  0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
  0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
  0xF0, 0x90, 0xF0, 0x90, 0x90, // A
  0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
  0xF0, 0x80, 0x80, 0x80, 0xF0, // C
  0xE0, 0x90, 0x90, 0x90, 0xE0, // D
  0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
  0xF0, 0x80, 0xF0, 0x80, 0x80  // F
];

// Memory map 
// 0x000-0x1FF - Chip 8 interpreter (contains font set in emu)
// 0x050-0x0A0 - Used for the built in 4x5 pixel font set (0-F)
// 0x200-0xFFF - Program ROM and work RAM

MEMORY_CAP :: 4096;
PROGRAM_START :: 0x200; // To support old CHIP-8 games, we should start storing the actual program at this address
FONT_START :: 0x50; // Starting address of where the system font is stored in memory

should_quit := false;

// The keys i need for the hexadecimal keyboard LMAO
KEY_DIGIT_1 :  : 49;
KEY_DIGIT_2 :  : 50;
KEY_DIGIT_3 :  : 51;
KEY_DIGIT_4 :  : 52;
KEY_Q       :  : 81;
KEY_W       :  : 87;
KEY_E       :  : 69;
KEY_R       :  : 82;
KEY_A       :  : 65;
KEY_S       :  : 83;
KEY_D       :  : 68;
KEY_F       :  : 70;
KEY_Z       :  : 90;
KEY_X       :  : 88;
KEY_C       :  : 67;
KEY_V       :  : 86; 

SEC_TO_MS :: 1000.0;
UPDATE_THERSHOLD_MS :: 16.67;

// Bunch of constants for opcodes here
CLS :: 0x00E0;
RET :: 0x00EE;
JP_ADDR :: 0x1_FFF;
CALL_ADDR :: 0x2_FFF;
SE_VX_BYTE :: 0x3_F_EE; // Skip next instr if Vx == EE
SNE_VX_BYTE :: 0x3_F_EE; // Skip next instr if Vx != EE
SE_VX_VY :: 0x5_FF_0;
LD_VX_BYTE :: 0x6_F_EE; // Set Vx = EE;
ADD_VX_BYTE :: 0x7_F_EE; // Add immediate value EE to Vx
LD_VX_VY :: 0x8_F_E_0; // Set Vx = Vy
OR_VX_VY :: 0x8_F_E_1; // Set Vx = Vx | Vy
AND_VX_VY :: 0x8_F_E_2; // Set Vx = Vx & Vy
XOR_VX_VY :: 0x8_F_E_3; // XOR
ADD_VX_VY :: 0x8_F_E_4; // Add vY into vX, is result > 255, set 0xF to 1 (carry)
SUB_VX_VY :: 0x8_F_E_5; // Sub vY from vX, is vX > vY, set 0xF to 1 (borrow)
SHR_VX    :: 0x8_F_0_6; // Set vX = vX SHR 1
SUBN_VX_VY :: 0x8_F_F_7;
SHL_VX    :: 0x8_F_0_8;
SNE_VX_VY :: 0x9_F_F_0; // Skip next instruction if vX != vY
LD_I_ADDR :: 0xA_FFF; // Set I = nnn
JP_V0_ADDR :: 0xB_FFF; // Set PC = NNN + V[0]
RND_VX_BYTE :: 0xC_F_FF; // Set vX = random_byte & KK

CHIP8 :: struct {
  opcode: u16;
  memory: [MEMORY_CAP]u8;
  V: [16]u8; // The 16 general purpose registers, 1 byte each
  I: u16; // Index register
  PC: u16; // Program counter
  display: Display; // Display used to draw stuff

  // each timer counts down at 60Hz (60 ticks per second) when above zero
  delay_timer: u16; 
  sound_timer: u16;

  stack: [16]u16;
  stack_pointer: u16;

  key: [16]u32;
}

chip8_init :: (chip8: *CHIP8) {
  chip8.PC = PROGRAM_START;

  // Copy font into program memory
  for i : 0..FONT.count-1 {
    chip8.memory[FONT_START + i] = FONT[i];
  }
}

chip8_load_cartridge :: (chip8: *CHIP8, filepath: string) {
  // Try to open file
  file, success := file_open(filepath, false, true, true);
  if !success {
    print("Failed to open cartridge file!\n");
    return;
  }
  defer file_close(*file);

  // Read entire file into byte array buffer
  length := file_length(file);
  buffer := cast(*u8)alloc(length);
  defer free(buffer);
  success = file_read(file, buffer, length);
  if !success {
    print("Could not read from cartridge file!\n");
    return;
  }

  // Convert the bytes into 2-byte instructions
  // program: [..]u16;
  // i := 0;
  // while i < length - 1 {
  //   low := cast(u16)buffer[i];
  //   high := cast(u16)buffer[i+1];
  //   array_add(*program, low << 8 | high);
  //   i += 2;
  // }

  // Copy the read cartridge buffer of bytes, into the chip8 memory block
  // Not sure about the endianess here, see above for a correct endianess implementation 
  for i : 0..length {
    chip8.memory[PROGRAM_START+i] = buffer[i];
  }
}

chip8_input :: (chip8: *CHIP8) {
  update_window_events();
  for event : events_this_frame {
    if event.type == .QUIT {
      should_quit = true;
    }
    else if event.type == .KEYBOARD {
      key := event.key_code;
      // Bottom row
      if key == KEY_Z then chip8.key[0] = event.key_pressed; 
      if key == KEY_X then chip8.key[1] = event.key_pressed; 
      if key == KEY_C then chip8.key[2] = event.key_pressed; 
      if key == KEY_V then chip8.key[3] = event.key_pressed;
      // Second row
      if key == KEY_A then chip8.key[4] = event.key_pressed; 
      if key == KEY_S then chip8.key[5] = event.key_pressed; 
      if key == KEY_D then chip8.key[6] = event.key_pressed; 
      if key == KEY_F then chip8.key[7] = event.key_pressed;
      // Third row 
      if key == KEY_Q then chip8.key[8] = event.key_pressed;
      if key == KEY_W then chip8.key[9] = event.key_pressed;
      if key == KEY_E then chip8.key[10] = event.key_pressed;
      if key == KEY_R then chip8.key[11] = event.key_pressed;
      // Last row
      if key == KEY_DIGIT_1 then chip8.key[12] = event.key_pressed;
      if key == KEY_DIGIT_2 then chip8.key[13] = event.key_pressed;
      if key == KEY_DIGIT_3 then chip8.key[14] = event.key_pressed;
      if key == KEY_DIGIT_4 then chip8.key[15] = event.key_pressed;
    }
  }
}

chip8_update :: (chip8: *CHIP8) {
  print("Update!!!\n");

  // update timers (at 60hz which is what update is ran at)
  chip8.delay_timer = max(chip8.delay_timer - 1, 0);
  chip8.sound_timer = max(chip8.sound_timer - 1, 0);

  // // execute instruction 
  // if chip8.PC == {

  // }
}

main :: () {
  chip8: CHIP8;
  display_init(*chip8.display, 512, 256, 64, 32, "IBM LOGO");

  chip8_init(*chip8);
  chip8_load_cartridge(*chip8, "./ibm_logo.ch8");

  last_update_ms := seconds_since_init() * SEC_TO_MS;

  while !should_quit {
    ms_now := seconds_since_init() * SEC_TO_MS;
    if ms_now - last_update_ms > UPDATE_THERSHOLD_MS {
      last_update_ms = ms_now;
      chip8_update(*chip8);
    }

    chip8_input(*chip8);  
  }
}

#import "Basic";
#import "Input";
#import "Random";
#import "File";
#load "display.jai";
#load "instructions.jai";