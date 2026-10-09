#!/usr/bin/env python3


import os
import sys

def encode_r(opcode, funct3, funct7, rd, rs1, rs2):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_i(opcode, funct3, rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_s(opcode, funct3, rs1, rs2, imm):
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0  = imm & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode

def encode_b(opcode, funct3, rs1, rs2, imm):
    imm_12   = (imm >> 12) & 0x1
    imm_11   = (imm >> 11) & 0x1
    imm_10_5 = (imm >> 5)  & 0x3F
    imm_4_1  = (imm >> 1)  & 0xF
    return (imm_12 << 31) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | \
           (funct3 << 12) | (imm_4_1 << 8) | (imm_11 << 7) | opcode

def encode_j(opcode, rd, imm):
    imm_20    = (imm >> 20) & 0x1
    imm_19_12 = (imm >> 12) & 0xFF
    imm_11    = (imm >> 11) & 0x1
    imm_10_1  = (imm >> 1)  & 0x3FF
    return (imm_20 << 31) | (imm_10_1 << 21) | (imm_11 << 20) | \
           (imm_19_12 << 12) | (rd << 7) | opcode

def add(rd, rs1, rs2):    return encode_r(0x33, 0x0, 0x00, rd, rs1, rs2)
def sub(rd, rs1, rs2):    return encode_r(0x33, 0x0, 0x20, rd, rs1, rs2)
def sll(rd, rs1, rs2):    return encode_r(0x33, 0x1, 0x00, rd, rs1, rs2)
def slt(rd, rs1, rs2):    return encode_r(0x33, 0x2, 0x00, rd, rs1, rs2)
def sltu(rd, rs1, rs2):   return encode_r(0x33, 0x3, 0x00, rd, rs1, rs2)
def xor(rd, rs1, rs2):    return encode_r(0x33, 0x4, 0x00, rd, rs1, rs2)
def srl(rd, rs1, rs2):    return encode_r(0x33, 0x5, 0x00, rd, rs1, rs2)
def sra(rd, rs1, rs2):    return encode_r(0x33, 0x5, 0x20, rd, rs1, rs2)
def or_op(rd, rs1, rs2):  return encode_r(0x33, 0x6, 0x00, rd, rs1, rs2)
def and_op(rd, rs1, rs2): return encode_r(0x33, 0x7, 0x00, rd, rs1, rs2)

def addi(rd, rs1, imm):   return encode_i(0x13, 0x0, rd, rs1, imm)
def slli(rd, rs1, imm):   return encode_i(0x13, 0x1, rd, rs1, imm)
def slti(rd, rs1, imm):   return encode_i(0x13, 0x2, rd, rs1, imm)
def sltiu(rd, rs1, imm):  return encode_i(0x13, 0x3, rd, rs1, imm)
def xori(rd, rs1, imm):   return encode_i(0x13, 0x4, rd, rs1, imm)
def srli(rd, rs1, imm):   return encode_i(0x13, 0x5, rd, rs1, imm)
def srai(rd, rs1, imm):   return encode_i(0x13, 0x5, rd, rs1, (imm & 0x1F) | 0x400)
def ori(rd, rs1, imm):    return encode_i(0x13, 0x6, rd, rs1, imm)
def andi(rd, rs1, imm):   return encode_i(0x13, 0x7, rd, rs1, imm)

def lw(rd, rs1, imm):     return encode_i(0x03, 0x2, rd, rs1, imm)
def sw(rs1, rs2, imm):    return encode_s(0x23, 0x2, rs1, rs2, imm)

def beq(rs1, rs2, imm):   return encode_b(0x63, 0x0, rs1, rs2, imm)
def bne(rs1, rs2, imm):   return encode_b(0x63, 0x1, rs1, rs2, imm)
def blt(rs1, rs2, imm):   return encode_b(0x63, 0x4, rs1, rs2, imm)
def bge(rs1, rs2, imm):   return encode_b(0x63, 0x5, rs1, rs2, imm)
def bltu(rs1, rs2, imm):  return encode_b(0x63, 0x6, rs1, rs2, imm)
def bgeu(rs1, rs2, imm):  return encode_b(0x63, 0x7, rs1, rs2, imm)

def jal(rd, imm):         return encode_j(0x6F, rd, imm)
def jalr(rd, rs1, imm):   return encode_i(0x67, 0x0, rd, rs1, imm)
def ebreak():             return encode_i(0x73, 0x0, 0, 0, 1)


class Assembler:
    def __init__(self):
        self.items = []

    def label(self, name):
        self.items.append(('label', name))

    def instr(self, fn, *args):
        self.items.append(('instr', fn, args))

    def assemble(self):

        label_pc = {}
        pc = 0
        for item in self.items:
            if item[0] == 'label':
                label_pc[item[1]] = pc
            else:
                pc += 4


        binary = []
        pc = 0
        for item in self.items:
            if item[0] == 'label':
                continue
            fn, args = item[1], list(item[2])
            for i, arg in enumerate(args):
                if isinstance(arg, str):
                    if arg not in label_pc:
                        raise ValueError(f"Undefined label: '{arg}'")
                    target_pc = label_pc[arg]
                    args[i] = target_pc - pc
            binary.append(fn(*args))
            pc += 4
        return binary


def gen_fibonacci():


    a = Assembler()
    a.instr(addi, 1, 0, 256)
    a.instr(addi, 2, 0, 20)
    a.instr(addi, 4, 0, 0)
    a.instr(sw, 1, 4, 0)
    a.instr(addi, 5, 0, 1)
    a.instr(sw, 1, 5, 4)
    a.instr(addi, 3, 0, 2)

    a.label("loop_start")
    a.instr(bge, 3, 2, "finish")
    a.instr(add, 6, 4, 5)
    a.instr(slli, 7, 3, 2)
    a.instr(add, 8, 1, 7)
    a.instr(sw, 8, 6, 0)
    a.instr(add, 4, 5, 0)
    a.instr(add, 5, 6, 0)
    a.instr(addi, 3, 3, 1)
    a.instr(jal, 0, "loop_start")

    a.label("finish")
    a.instr(ebreak)
    return a.assemble()


def gen_bubble_sort():


    a = Assembler()

    a.instr(addi, 1, 0, 0)
    a.instr(addi, 2, 0, 16)
    a.instr(addi, 3, 0, 0)
    a.instr(addi, 4, 0, 15)

    a.label("init_loop")
    a.instr(bge, 3, 2, "init_done")
    a.instr(slli, 5, 3, 2)
    a.instr(add, 6, 1, 5)
    a.instr(sw, 6, 4, 0)
    a.instr(addi, 4, 4, -1)
    a.instr(addi, 3, 3, 1)
    a.instr(jal, 0, "init_loop")

    a.label("init_done")

    a.instr(addi, 10, 0, 0)
    a.instr(addi, 11, 2, -1)

    a.label("outer_loop")
    a.instr(bge, 10, 11, "sort_done")
    a.instr(addi, 12, 0, 0)
    a.instr(sub, 13, 11, 10)

    a.label("inner_loop")
    a.instr(bge, 12, 13, "next_outer")
    a.instr(slli, 14, 12, 2)
    a.instr(add, 15, 1, 14)
    a.instr(lw, 16, 15, 0)
    a.instr(lw, 17, 15, 4)
    a.instr(bge, 17, 16, "no_swap")
    a.instr(sw, 15, 17, 0)
    a.instr(sw, 15, 16, 4)

    a.label("no_swap")
    a.instr(addi, 12, 12, 1)
    a.instr(jal, 0, "inner_loop")

    a.label("next_outer")
    a.instr(addi, 10, 10, 1)
    a.instr(jal, 0, "outer_loop")

    a.label("sort_done")
    a.instr(ebreak)
    return a.assemble()


def gen_sensor_threshold():


    a = Assembler()

    a.instr(addi, 1, 0, 0)
    a.instr(addi, 2, 0, 256)
    a.instr(addi, 3, 0, 45)
    a.instr(addi, 4, 0, 16)
    a.instr(addi, 5, 0, 0)
    a.instr(addi, 6, 0, 0)

    a.label("loop_start")
    a.instr(bge, 5, 4, "finish")
    a.instr(slli, 7, 5, 2)
    a.instr(add, 8, 1, 7)
    a.instr(lw, 9, 8, 0)
    a.instr(add, 10, 2, 7)


    a.instr(blt, 9, 3, "normal")


    a.instr(addi, 11, 0, 1)
    a.instr(sw, 10, 11, 0)
    a.instr(addi, 6, 6, 1)
    a.instr(jal, 0, "next_iter")


    a.label("normal")
    a.instr(addi, 11, 0, 0)
    a.instr(sw, 10, 11, 0)


    a.label("next_iter")
    a.instr(addi, 5, 5, 1)
    a.instr(jal, 0, "loop_start")


    a.label("finish")
    a.instr(addi, 12, 0, 384)
    a.instr(sw, 12, 6, 0)
    a.instr(ebreak)
    return a.assemble()


def write_hex(filename, instrs):
    with open(filename, 'w') as f:
        for instr in instrs:
            f.write(f"{instr:08x}\n")
    print(f"Generated {filename} ({len(instrs)} instructions, {len(instrs)*4} bytes)")


if __name__ == '__main__':
    prog_dir = os.path.dirname(os.path.abspath(__file__))

    fib_instrs = gen_fibonacci()
    write_hex(os.path.join(prog_dir, 'fibonacci.hex'), fib_instrs)

    sort_instrs = gen_bubble_sort()
    write_hex(os.path.join(prog_dir, 'bubble_sort.hex'), sort_instrs)

    sensor_instrs = gen_sensor_threshold()
    write_hex(os.path.join(prog_dir, 'sensor_threshold.hex'), sensor_instrs)

    print("\nAll 3 demo programs successfully assembled!")
