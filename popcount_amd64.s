// Copyright 2016 Tom Thorogood. All rights reserved.
// Use of this source code is governed by a
// Modified BSD License license that can be found in
// the LICENSE file.

// +build amd64,!gccgo,!appengine

#include "textflag.h"

// func countBytesASM(data *byte, len uint64) uint64
TEXT ·countBytesASM(SB),NOSPLIT,$0
	MOVQ data+0(FP), SI
	MOVQ len+8(FP), CX

	/*
	 * Important performance information can be found at:
	 * http://stackoverflow.com/a/25089720
	 *
	 * POPCNT has a false-dependency bug that causes a
	 * performance hit. Thus, in bigloop four separate
	 * destination registers are used to allow
	 * intra-loop parallelization, also and in loop the
	 * the destination register is cleared (with no
	 * practical effect) before POPCNT to allow
	 * inter-loop parallelization.
	 */

	XORQ AX, AX

	CMPQ CX, $8
	JB tail

	CMPQ CX, $32
	JB loop

bigloop:
	POPCNTQ -8(SI)(CX*1), R11
	POPCNTQ -16(SI)(CX*1), R10
	POPCNTQ -24(SI)(CX*1), R9
	POPCNTQ -32(SI)(CX*1), R8

	ADDQ R11, AX
	ADDQ R10, AX
	ADDQ R9, AX
	ADDQ R8, AX

	SUBQ $32, CX
	JZ ret

	CMPQ CX, $32
	JGE bigloop

	CMPQ CX, $8
	JB tail

loop:
	XORQ DX, DX
	POPCNTQ -8(SI)(CX*1), DX
	ADDQ DX, AX

	SUBQ $8, CX
	JZ ret

	CMPQ CX, $8
	JGE loop

tail:
	XORQ DX, DX

	CMPQ CX, $4
	JB tail_2

	MOVL -4(SI)(CX*1), DX

	SUBQ $4, CX
	JZ tail_4

tail_2:
	CMPQ CX, $2
	JB tail_3

	SHLQ $16, DX
	ORW -2(SI)(CX*1), DX

	SUBQ $2, CX
	JZ tail_4

tail_3:
	TESTQ CX, CX
	JZ tail_4

	SHLQ $8, DX
	ORB -1(SI)(CX*1), DX

tail_4:
	POPCNTQ DX, DX
	ADDQ DX, AX

ret:
	MOVQ AX, ret+16(FP)
	RET