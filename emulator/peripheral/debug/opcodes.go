/*
Copyright (c) 2019-2020 Andreas T Jonsson

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
*/

package debug

import "fmt"

func OpcodeName(opcode byte) string {
	if name, ok := instructionNames[opcode]; ok {
		return name
	}
	return fmt.Sprintf("NO NAME (0x%X)", opcode)
}

var instructionNames = map[byte]string{
	0x00: "ADD r/m8,r8",
	0x01: "ADD r/m16,r16",
	0x02: "ADD r8,r/m8",
	0x03: "ADD r16,r/m16",
	0x04: "ADD AL,d8",
	0x05: "ADD AX,d16",
	0x06: "PUSH ES",
	0x07: "POP ES",
	0x08: "OR r/m8,r8",
	0x09: "OR r/m16,r16",
	0x0A: "OR r8,r/m8",
	0x0B: "OR r16,r/m16",
	0x0C: "OR AL,d8",
	0x0D: "OR AX,d16",
	0x0E: "PUSH CS",
	0x0F: "*POP CS",

	0x10: "ADC r/m8,r8",
	0x11: "ADC r/m16,r16",
	0x12: "ADC r8,r/m8",
	0x13: "ADC r16,r/m16",
	0x14: "ADC AL,d8",
	0x15: "ADC AX,d16",
	0x16: "PUSH SS",
	0x17: "POP SS",
	0x18: "SBB r/m8,r8",
	0x19: "SBB r/m16,r16",
	0x1A: "SBB r8,r/m8",
	0x1B: "SBB r16,r/m16",
	0x1C: "SBB AL,d8",
	0x1D: "SBB AX,d16",
	0x1E: "PUSH DS",
	0x1F: "POP DS",

	0x20: "AND r/m8,r8",
	0x21: "AND r/m16,r16",
	0x22: "AND r8,r/m8",
	0x23: "AND r16,r/m16",
	0x24: "AND AL,d8",
	0x25: "AND AX,d16",
	0x26: "ES:",
	0x27: "DAA",
	0x28: "SUB r/m8,r8",
	0x29: "SUB r/m16,r16",
	0x2A: "SUB r8,r/m8",
	0x2B: "SUB r16,r/m16",
	0x2C: "SUB AL,d8",
	0x2D: "SUB AX,d16",
	0x2E: "CS:",
	0x2F: "DAS",

	0x30: "XOR r/m8,r8",
	0x31: "XOR r/m16,r16",
	0x32: "XOR r8,r/m8",
	0x33: "XOR r16,r/m16",
	0x34: "XOR AL,d8",
	0x35: "XOR AX,d16",
	0x36: "SS:",
	0x37: "AAA",
	0x38: "CMP r/m8,r8",
	0x39: "CMP r/m16,r16",
	0x3A: "CMP r8,r/m8",
	0x3B: "CMP r16,r/m16",
	0x3C: "CMP AL,d8",
	0x3D: "CMP AX,d16",
	0x3E: "DS:",
	0x3F: "AAS",

	0x40: "INC AX",
	0x41: "INC CX",
	0x42: "INC DX",
	0x43: "INC BX",
	0x44: "INC SP",
	0x45: "INC BP",
	0x46: "INC SI",
	0x47: "INC DI",
	0x48: "DEC AX",
	0x49: "DEC CX",
	0x4A: "DEC DX",
	0x4B: "DEC BX",
	0x4C: "DEC SP",
	0x4D: "DEC BP",
	0x4E: "DEC SI",
	0x4F: "DEC DI",

	0x50: "PUSH AX",
	0x51: "PUSH CX",
	0x52: "PUSH DX",
	0x53: "PUSH BX",
	0x54: "PUSH SP",
	0x55: "PUSH BP",
	0x56: "PUSH SI",
	0x57: "PUSH DI",
	0x58: "POP AX",
	0x59: "POP CX",
	0x5A: "POP DX",
	0x5B: "POP BX",
	0x5C: "POP SP",
	0x5D: "POP BP",
	0x5E: "POP SI",
	0x5F: "POP DI",

	0x60: "PUSHA (80186)",
	0x61: "POPA (80186)",
	0x69: "IMUL r/m16,d8 (80186)",
	0x6B: "IMUL r/m16,d16 (80186)",

	0x70: "JO rel8",
	0x71: "JNO rel8",
	0x72: "JB/JNAE rel8",
	0x73: "JNB/JAE rel8",
	0x74: "JE/JZ rel8",
	0x75: "JNE/JNZ rel8",
	0x76: "JBE/JNA rel8",
	0x77: "JNBE/JA rel8",
	0x78: "JS rel8",
	0x79: "JNS rel8",
	0x7A: "JP/JPE rel8",
	0x7B: "JNP/JPO rel8",
	0x7C: "JL/JNGE rel8",
	0x7D: "JNL/JGE rel8",
	0x7E: "JLE/JNG rel8",
	0x7F: "JNLE/JG rel8",

	0x80: "_ALU1 r/m8,d8",
	0x81: "_ALU1 r/m16,d16",
	0x82: "*_ALU1 r/m8,d8",
	0x83: "_ALU1 r/m16,d8",
	0x84: "TEST r/m8,r8",
	0x85: "TEST r/m16,r16",
	0x86: "XCHG r8,r/m8",
	0x87: "XCHG r16,r/m16",
	0x88: "MOV r/m8,r8",
	0x89: "MOV r/m16,r16",
	0x8A: "MOV r8,r/m8",
	0x8B: "MOV r16,r/m16",
	0x8C: "_MOV r/m16,sr",
	0x8D: "LEA r16,r/m16",
	0x8E: "_MOV sr,r/m16",
	0x8F: "_POP r/m16",

	0x90: "NOP",
	0x91: "XCHG AX,CX",
	0x92: "XCHG AX,DX",
	0x93: "XCHG AX,BX",
	0x94: "XCHG AX,SP",
	0x95: "XCHG AX,BP",
	0x96: "XCHG AX,SI",
	0x97: "XCHG AX,DI",
	0x98: "CBW",
	0x99: "CWD",
	0x9A: "CALL seg:a16",
	0x9B: "WAIT",
	0x9C: "PUSHF",
	0x9D: "POPF",
	0x9E: "SAHF",
	0x9F: "LAHF",

	0xA0: "MOV AL,[addr]",
	0xA1: "MOV AX,[addr]",
	0xA2: "MOV [addr],AL",
	0xA3: "MOV [addr],AX",
	0xA4: "MOVSB",
	0xA5: "MOVSW",
	0xA6: "CMPSB",
	0xA7: "CMPSW",
	0xA8: "TEST AL,d8",
	0xA9: "TEST AX,d16",
	0xAA: "STOSB",
	0xAB: "STOSW",
	0xAC: "LODSB",
	0xAD: "LODSW",
	0xAE: "SCASB",
	0xAF: "SCASW",

	0xB0: "MOV AL,d8",
	0xB1: "MOV CL,d8",
	0xB2: "MOV DL,d8",
	0xB3: "MOV BL,d8",
	0xB4: "MOV AH,d8",
	0xB5: "MOV CH,d8",
	0xB6: "MOV DH,d8",
	0xB7: "MOV BH,d8",
	0xB8: "MOV AX,d16",
	0xB9: "MOV CX,d16",
	0xBA: "MOV DX,d16",
	0xBB: "MOV BX,d16",
	0xBC: "MOV SP,d16",
	0xBD: "MOV BP,d16",
	0xBE: "MOV SI,d16",
	0xBF: "MOV DI,d16",

	0xC0: "SHL r/m8,d8 (80186)",
	0xC1: "SHL r/m16,d16 (80186)",
	0xC2: "RET d16",
	0xC3: "RET",
	0xC4: "LES r16,m32",
	0xC5: "LDS r16,m32",
	0xC6: "_MOV r/m8,d8",
	0xC7: "_MOV r/m16,d16",
	0xC8: "ENTER (80186)",
	0xC9: "LEAVE (80186)",
	0xCA: "RETF d16",
	0xCB: "RETF",
	0xCC: "INT 3",
	0xCD: "INT d8",
	0xCE: "INTO",
	0xCF: "IRET",

	0xD0: "_ROT r/m8,1",
	0xD1: "_ROT r/m16,1",
	0xD2: "_ROT r/m8,CL",
	0xD3: "_ROT r/m16,CL",
	0xD4: "AAM *d8",
	0xD5: "AAD *d8",
	0xD6: "*SALC",
	0xD7: "XLAT",
	0xD8: "ESC 0",
	0xD9: "ESC 1",
	0xDA: "ESC 2",
	0xDB: "ESC 3",
	0xDC: "ESC 4",
	0xDD: "ESC 5",
	0xDE: "ESC 6",
	0xDF: "ESC 7",

	0xE0: "LOOPNZ/NE rel8",
	0xE1: "LOOPZ/E rel8",
	0xE2: "LOOP rel8",
	0xE3: "JCXZ rel8",
	0xE4: "IN AL,[d8]",
	0xE5: "IN AX,[d8]",
	0xE6: "OUT [d8],AL",
	0xE7: "OUT [d8],AX",
	0xE8: "CALL rel16",
	0xE9: "JMP rel16",
	0xEA: "JMP seg:a16",
	0xEB: "JMP rel8",
	0xEC: "IN AL,[DX]",
	0xED: "IN AX,[DX]",
	0xEE: "OUT [DX],AL",
	0xEF: "OUT [DX],AX",

	0xF0: "LOCK",
	0xF2: "REPNE/REPNZ",
	0xF3: "REP/REPE/REPZ",
	0xF4: "HLT",
	0xF5: "CMC",
	0xF6: "_ALU2 r/m8,d8",
	0xF7: "_ALU2 r/m16,d16",
	0xF8: "CLC",
	0xF9: "STC",
	0xFA: "CLI",
	0xFB: "STI",
	0xFC: "CLD",
	0xFD: "STD",
	0xFE: "_MISC r/m8",
	0xFF: "_MISC r/m16",
}
