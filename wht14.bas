' Walsh Hadamard transform, random projection algorithms and vector ops.
' You could use the FreeBasic 1.05 compiler to create a Linux AMD64 shared
' library to use with C or whatever. You would be far better off writing GPU code.    
namespace rp
sub hsixteen naked (x as single ptr, n as ulongint,scale as single)
asm	
	shufps xmm0,xmm0,0
	.align 16
h16:
	subq rsi,16
	movups xmm1,[rdi]
	movups xmm2,[rdi+16]
	movups xmm3,[rdi+2*16]
	movups xmm4,[rdi+3*16]
	movups xmm5,xmm1
	movups xmm6,xmm3
	haddps xmm1,xmm2
	haddps xmm3,xmm4
	hsubps xmm5,xmm2
	hsubps xmm6,xmm4
	movups xmm2,xmm1
	movups xmm4,xmm3
	haddps xmm1,xmm5
	haddps xmm3,xmm6
	hsubps xmm2,xmm5
	hsubps xmm4,xmm6
	movups xmm5,xmm1
	movups xmm6,xmm3
	haddps xmm1,xmm2
	haddps xmm3,xmm4
	hsubps xmm5,xmm2
	hsubps xmm6,xmm4
	movups xmm2,xmm1
	movups xmm4,xmm5
	addps xmm1,xmm3
	addps xmm5,xmm6
	subps xmm2,xmm3
	subps xmm4,xmm6
	mulps xmm1,xmm0
	mulps xmm5,xmm0
	mulps xmm2,xmm0
	mulps xmm4,xmm0
	movups [rdi],xmm1
	movups [rdi+16],xmm5
	movups [rdi+2*16],xmm2
	movups [rdi+3*16],xmm4
	lea rdi,[rdi+64]
	jnz h16
	ret
end asm
end sub

sub hgap naked (x as single ptr,gap as ulongint,n as ulongint)
asm
    movq rcx,rsi
	lea r8,[rdi+4*rsi]
	shr rdx,1
	.align 16	
hgaploop:
	subq rcx,16
	movups xmm0,[rdi]
	movups xmm1,[rdi+16]
	movups xmm2,[rdi+2*16]
	movups xmm3,[rdi+3*16]
	movups xmm8,[r8]
	movups xmm9,[r8+16]
	movups xmm10,[r8+2*16]
	movups xmm11,[r8+3*16]
	movups xmm4,xmm0
	movups xmm5,xmm1
	movups xmm6,xmm2
	movups xmm7,xmm3
	addps xmm0,xmm8
	addps xmm1,xmm9
	addps xmm2,xmm10
	addps xmm3,xmm11
	subps xmm4,xmm8
	subps xmm5,xmm9
	subps xmm6,xmm10
	subps xmm7,xmm11
	movups [rdi],xmm0
	movups [rdi+16],xmm1
	movups [rdi+2*16],xmm2
	movups [rdi+3*16],xmm3
	movups [r8],xmm4
	movups [r8+16],xmm5
	movups [r8+2*16],xmm6
	movups [r8+3*16],xmm7
	lea rdi,[rdi+64]
	lea r8,[r8+64]
	jnz hgaploop
	subq rdx,rsi
	movq rcx,rsi
	movq rdi,r8
	lea r8,[r8+4*rsi]
	jnz hgaploop
	ret
end asm
end sub

' n must be a power of 2, 16 or over 16,32,64....
sub wht(vec as single ptr, n as ulongint)
	   const lim as ulongint=8192
	   dim as ulongint gap,k
	   dim as single scale=1.0/sqr(n)
	   k=n
	   if k>lim then k=lim
	   for i as ulongint=0 to n-1 step lim
		   hsixteen(vec+i,k,scale)
		   gap=16
		   while gap<k
			  hgap(vec+i,gap,k)
			  gap+=gap
		   wend
		next
		while gap<n
			hgap(vec,gap,n)
			gap+=gap
		wend	
end sub

'linear congruent rng
sub hashflipA naked (result as single ptr,x as single ptr,h as ulongint,n as ulongint)
asm
	movq rax,rndphi[rip]
	movq r8,rndsqr3[rip]
	imulq rdx,rax
	movdqu xmm8,flipshift[rip]
	movdqu xmm9,flipshift[rip+16]
	add rdx,r8
	movdqu xmm10,flipshift[rip+32]
	imulq rdx,rax
	movdqu xmm11,flipshift[rip+48]
	movdqu xmm12,flipmask[rip]
	movd xmm4,edx
	.align 16
flipAlp:
	imulq rdx,rax
	pshufd xmm4,xmm4,0
	movdqu xmm0,[rsi]
	movdqu xmm1,[rsi+16]
	movdqu xmm2,[rsi+2*16]
	movdqu xmm3,[rsi+3*16]
	addq rdx,r8
	movdqa xmm5,xmm4
	movdqa xmm6,xmm4
	movdqa xmm7,xmm4
	imulq rdx,rax
	pmulld xmm4,xmm8
	pmulld xmm5,xmm9
	pmulld xmm6,xmm10
	pmulld xmm7,xmm11
	addq rdx,r8
	pand xmm4,xmm12
	pand xmm5,xmm12
	pand xmm6,xmm12
	pand xmm7,xmm12
	bswapq rdx
	pxor xmm0,xmm4
	pxor xmm1,xmm5
	pxor xmm2,xmm6
	pxor xmm3,xmm7
	movd xmm4,edx
	sub rcx,16
	movdqu [rdi],xmm0
	movdqu [rdi+16],xmm1
	movdqu [rdi+2*16],xmm2
	movdqu [rdi+3*16],xmm3
	lea rsi,[rsi+64]
	lea rdi,[rdi+64]
	jnz flipAlp
	ret
 flipshift:   .int 1,2,4,8,16,32,64,128
			   .int 256,512,1024,2048,4096,8192,16384,32768
 flipmask:	   .int 0x80000000,0x80000000,0x80000000,0x80000000
 rndphi:	   .quad 0x9E3779B97F4A7C15
 rndsqr3:	   .quad 0xBB67AE8584CAA73B
end asm
end sub

'linear congruent rng
sub hashflipB naked (result as single ptr,x as single ptr,h as ulongint,n as ulongint)
asm
	movq rax,rndsqr3[rip]
	movq r8,rndphi[rip]
	imulq rdx,rax
	movdqu xmm8,flipshift[rip]
	movdqu xmm9,flipshift[rip+16]
	add rdx,r8
	movdqu xmm10,flipshift[rip+32]
	imulq rdx,rax
	movdqu xmm11,flipshift[rip+48]
	movdqu xmm12,flipmask[rip]
	movd xmm4,edx
	.align 16
flipBlp:
	imulq rdx,rax
	pshufd xmm4,xmm4,0
	movdqu xmm0,[rsi]
	movdqu xmm1,[rsi+16]
	movdqu xmm2,[rsi+2*16]
	movdqu xmm3,[rsi+3*16]
	addq rdx,r8
	movdqa xmm5,xmm4
	movdqa xmm6,xmm4
	movdqa xmm7,xmm4
	imulq rdx,rax
	pmulld xmm4,xmm8
	pmulld xmm5,xmm9
	pmulld xmm6,xmm10
	pmulld xmm7,xmm11
	addq rdx,r8
	pand xmm4,xmm12
	pand xmm5,xmm12
	pand xmm6,xmm12
	pand xmm7,xmm12
	bswapq rdx
	pxor xmm0,xmm4
	pxor xmm1,xmm5
	pxor xmm2,xmm6
	pxor xmm3,xmm7
	movd xmm4,edx
	sub rcx,16
	movdqu [rdi],xmm0
	movdqu [rdi+16],xmm1
	movdqu [rdi+2*16],xmm2
	movdqu [rdi+3*16],xmm3
	lea rsi,[rsi+64]
	lea rdi,[rdi+64]
	jnz flipBlp
	ret
end asm
end sub

sub hashpermute naked (x as single ptr,h as ulong,n as ulongint)
asm	
	push r12
	push r13
	push r14
	push r15
	.align 16
hashprmlp:
	lea r11d,[edx+esi]
	lea r10d,[edx+esi-1]
	lea r9d,[edx+esi-2]
	lea r8d,[edx+esi-3]
	imul r11d,741103597
	imul r10d,887987685
	imul r9d,1597334677
	imul r8d,204209821
	bswap r11d
	bswap r10d
	bswap r9d
	bswap r8d
	add r11d,0x79f43981
	add r10d,0xb5c84c33
	add r9d,0x5e5c7f2b
    add r8d,0x9be72e55
    imul r11d,741103597
	imul r10d,887987685
	imul r9d,1597334677
	imul r8d,204209821
    lea r15,[rdx]
    lea r14,[rdx-1]
    lea r13,[rdx-2]
    lea r12,[rdx-3]
    imulq r11,r15
    imulq r10,r14
    imulq r9,r13
    imulq r8,r12
    shrq r11,32
    shrq r10,32
    shrq r9,32
    shrq r8,32
    mov eax,[rdi+4*rdx-4]
    mov ecx,[rdi+4*r11]
    mov [rdi+4*r11],eax
    mov [rdi+4*rdx-4],ecx
    mov eax,[rdi+4*rdx-8]
    mov ecx,[rdi+4*r10]
    mov [rdi+4*r10],eax
    mov [rdi+4*rdx-8],ecx  
    mov eax,[rdi+4*rdx-12]
    mov ecx,[rdi+4*r9]
    mov [rdi+4*r9],eax
    mov [rdi+4*rdx-12],ecx
    mov eax,[rdi+4*rdx-16]
    mov ecx,[rdi+4*r8]
    mov [rdi+4*r8],eax
    mov [rdi+4*rdx-16],ecx
    sub rdx,4
    jnz hashprmlp
    pop r15
    pop r14
    pop r13
    pop r12
    ret
end asm
end sub


sub hashpermuteinv naked (x as single ptr,h as ulong,n as ulongint)
asm
	push r12
	push r13
	push r14
	push r15
	push rbx
	mov rbx,4
	.align 16
hashprminvlp:
	lea r8,[rbx+rsi-3]
	lea r9,[rbx+rsi-2]
	lea r10,[rbx+rsi-1]
	lea r11,[rbx+rsi]
	imul r8d,204209821
	imul r9d,1597334677
	imul r10d,887987685
	imul r11d,741103597
	bswap r8d
	bswap r9d
	bswap r10d
	bswap r11d
	add r8d,0x9be72e55
	add r9d,0x5e5c7f2b
	add r10d,0xb5c84c33
	add r11d,0x79f43981
	imul r8d,204209821
	imul r9d,1597334677
    imul r10d,887987685
    imul r11d,741103597
	lea r12,[rbx-3]
	lea r13,[rbx-2]
    lea r14,[rbx-1]
    lea r15,[rbx]
    imulq r8,r12
    imulq r9,r13
    imulq r10,r14
    imulq r11,r15
    shrq r8,32
    shrq r9,32
    shrq r10,32
    shrq r11,32 
    mov eax,[rdi+4*rbx-16]
    mov ecx,[rdi+4*r8]
    mov [rdi+4*r8],eax
    mov [rdi+4*rbx-16],ecx
    mov eax,[rdi+4*rbx-12]
    mov ecx,[rdi+4*r9]
    mov [rdi+4*r9],eax
    mov [rdi+4*rbx-12],ecx
    mov eax,[rdi+4*rbx-8]
    mov ecx,[rdi+4*r10]
    mov [rdi+4*r10],eax
    mov [rdi+4*rbx-8],ecx
    mov eax,[rdi+4*rbx-4]
    mov ecx,[rdi+4*r11]
    mov [rdi+4*r11],eax
    mov [rdi+4*rbx-4],ecx
    sub rdx,4
    lea rbx,[rbx+4]
    jnz hashprminvlp
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret
end asm
end sub

sub multiplyscalar naked (result as single ptr,x as single ptr,value as single,n as ulongint)
asm
	subq rdx,16
	shufps XMM0,XMM0,0
	.align 16
mulscalarlp:
	movups xmm1,[rsi+4*rdx+16*3]
	movups xmm2,[rsi+4*rdx+16*2]
	movups xmm3,[rsi+4*rdx+16]
	movups xmm4,[rsi+4*rdx]
	subq rdx,16
	mulps xmm1,xmm0
	mulps xmm2,xmm0
	mulps xmm3,xmm0
	mulps xmm4,xmm0
	movups [rdi+4*rdx+64+16*3],xmm1
	movups [rdi+4*rdx+64+16*2],xmm2
	movups [rdi+4*rdx+64+16],xmm3
	movups [rdi+4*rdx+64],xmm4
	jnc mulscalarlp
	ret
end asm
end sub
	
sub addscalar naked (result as single ptr,x as single ptr,value as single, n as ulongint)
asm
	subq rdx,16
	shufps XMM0,XMM0,0
	.align 16
addscalarlp:
	movups xmm1,[rsi+4*rdx+16*3]
	movups xmm2,[rsi+4*rdx+16*2]
	movups xmm3,[rsi+4*rdx+16]
	movups xmm4,[rsi+4*rdx]
	subq rdx,16
	addps xmm1,xmm0
	addps xmm2,xmm0
	addps xmm3,xmm0
	addps xmm4,xmm0
	movups [rdi+4*rdx+64+16*3],xmm1
	movups [rdi+4*rdx+64+16*2],xmm2
	movups [rdi+4*rdx+64+16],xmm3
	movups [rdi+4*rdx+64],xmm4
	jnc addscalarlp
	ret
end asm
end sub

sub	clipmin naked (result as single ptr,x as single ptr,min as single,n as ulongint)
asm
	subq rdx,16
	shufps XMM0,XMM0,0
	.align 16
clipminlp:
	movups xmm1,[rsi+4*rdx+16*3]
	movups xmm2,[rsi+4*rdx+16*2]
	movups xmm3,[rsi+4*rdx+16]
	movups xmm4,[rsi+4*rdx]
	subq rdx,16
	maxps xmm1,xmm0
	maxps xmm2,xmm0
	maxps xmm3,xmm0
	maxps xmm4,xmm0
	movups [rdi+4*rdx+64+16*3],xmm1
	movups [rdi+4*rdx+64+16*2],xmm2
	movups [rdi+4*rdx+64+16],xmm3
	movups [rdi+4*rdx+64],xmm4
	jnc clipminlp
	ret
end asm
end sub

sub	clipmax naked (result as single ptr,x as single ptr,max as single,n as ulongint)
asm
	subq rdx,16
	shufps XMM0,XMM0,0
	.align 16
clipmaxlp:
	movups xmm1,[rsi+4*rdx+16*3]
	movups xmm2,[rsi+4*rdx+16*2]
	movups xmm3,[rsi+4*rdx+16]
	movups xmm4,[rsi+4*rdx]
	subq rdx,16
	minps xmm1,xmm0
	minps xmm2,xmm0
	minps xmm3,xmm0
	minps xmm4,xmm0
	movups [rdi+4*rdx+64+16*3],xmm1
	movups [rdi+4*rdx+64+16*2],xmm2
	movups [rdi+4*rdx+64+16],xmm3
	movups [rdi+4*rdx+64],xmm4
	jnc clipmaxlp
	ret
end asm
end sub

sub	clip naked (result as single ptr,x as single ptr,min as single,max as single,n as ulongint)
asm
	subq rdx,16
	shufps XMM0,XMM0,0
	shufps xmm1,xmm1,0
	.align 16
cliplp:
	movups xmm2,[rsi+4*rdx+16*3]
	movups xmm3,[rsi+4*rdx+16*2]
	movups xmm4,[rsi+4*rdx+16]
	movups xmm5,[rsi+4*rdx]
	subq rdx,16
	maxps xmm2,xmm0
	maxps xmm3,xmm0
	maxps xmm4,xmm0
	maxps xmm5,xmm0
	minps xmm2,xmm1
	minps xmm3,xmm1
	minps xmm4,xmm1
	minps xmm5,xmm1
	movups [rdi+4*rdx+64+16*3],xmm2
	movups [rdi+4*rdx+64+16*2],xmm3
	movups [rdi+4*rdx+64+16],xmm4
	movups [rdi+4*rdx+64],xmm5
	jnc cliplp
	ret
end asm 
end sub

sub zero naked (result as single ptr,n as ulongint)
asm
	pxor XMM0,XMM0
	.align 16
zerolp:
	subq rsi,16
	movups [rdi+4*rsi+16*3],xmm0
	movups [rdi+4*rsi+16*2],xmm0
	movups [rdi+4*rsi+16],xmm0
	movups [rdi+4*rsi],xmm0
	jnz zerolp
	ret
end asm
end sub

sub copy naked (result as single ptr, x as single ptr,n as ulongint)
asm
	subq rdx,16
	.align 16
copylp:
	movups xmm0,[rsi+4*rdx+16*3]
	movups xmm1,[rsi+4*rdx+16*2]
	movups xmm2,[rsi+4*rdx+16]
	movups xmm3,[rsi+4*rdx]
	subq rdx,16
	movups [rdi+4*rdx+64+16*3],xmm0
	movups [rdi+4*rdx+64+16*2],xmm1
	movups [rdi+4*rdx+64+16],xmm2
	movups [rdi+4*rdx+64],xmm3
	jnc copylp
	ret
end asm
end sub

sub absolute naked (result as single ptr,x as single ptr,n as ulongint)
asm
	subq rdx,16
	mov ecx,0x7fffffff
	movd xmm4,ecx
	pshufd xmm4,xmm4,0
	.align 16
absolutelp:
	movups xmm0,[rsi+4*rdx+16*3]
	movups xmm1,[rsi+4*rdx+16*2]
	movups xmm2,[rsi+4*rdx+16]
	movups xmm3,[rsi+4*rdx]
	subq rdx,16
	andps xmm0,xmm4
    andps xmm1,xmm4
    andps xmm2,xmm4
    andps xmm3,xmm4
	movups [rdi+4*rdx+64+16*3],xmm0
	movups [rdi+4*rdx+64+16*2],xmm1
	movups [rdi+4*rdx+64+16],xmm2
	movups [rdi+4*rdx+64],xmm3
	jnc absolutelp
	ret
end asm
end sub

sub multiply naked(result as single ptr,x as single ptr,y as single ptr,n as ulongint)
asm
	subq rcx,16
	.align 16
multiplylp:
	movups xmm0,[rsi+4*rcx+16*3]
	movups xmm1,[rsi+4*rcx+16*2]
	movups xmm2,[rsi+4*rcx+16]
	movups xmm3,[rsi+4*rcx]
	mulps xmm0,[rdx+4*rcx+16*3]
    mulps xmm1,[rdx+4*rcx+16*2]
    mulps xmm2,[rdx+4*rcx+16*1]
    mulps xmm3,[rdx+4*rcx]
    subq rcx,16
	movups [rdi+4*rcx+64+16*3],xmm0
	movups [rdi+4*rcx+64+16*2],xmm1
	movups [rdi+4*rcx+64+16],xmm2
	movups [rdi+4*rcx+64],xmm3
	jnc multiplylp
	ret
end asm
end sub

sub multiplyaddto naked (result as single ptr,x as single ptr,y as single ptr,n as ulongint)
asm
	subq rcx,16
	.align 16
multiplyaddtolp:
	movups xmm0,[rsi+4*rcx+16*3]
	movups xmm1,[rsi+4*rcx+16*2]
	movups xmm2,[rsi+4*rcx+16]
	movups xmm3,[rsi+4*rcx]
	movups xmm4,[rdi+4*rcx+16*3]
	movups xmm5,[rdi+4*rcx+16*2]
	movups xmm6,[rdi+4*rcx+16]
	movups xmm7,[rdi+4*rcx]
	
	mulps xmm0,[rdx+4*rcx+16*3]
    mulps xmm1,[rdx+4*rcx+16*2]
    mulps xmm2,[rdx+4*rcx+16*1]
    mulps xmm3,[rdx+4*rcx]
    subq rcx,16
    addps xmm0,xmm4
    addps xmm1,xmm5
    addps xmm2,xmm6
    addps xmm3,xmm7
	movups [rdi+4*rcx+64+16*3],xmm0
	movups [rdi+4*rcx+64+16*2],xmm1
	movups [rdi+4*rcx+64+16],xmm2
	movups [rdi+4*rcx+64],xmm3
	jnc multiplyaddtolp
	ret	
end asm
end sub

sub multiply3addto naked (result as single ptr,x as single ptr,y as single ptr,z as single ptr,n as ulongint)
asm
	.align 16
multiply3addtolp:
	movups xmm12,[rcx]
	movups xmm13,[rcx+16]
	movups xmm14,[rcx+2*16]
	movups xmm15,[rcx+3*16]
	
	movups xmm8,[rdx]
	movups xmm9,[rdx+16]
	movups xmm10,[rdx+2*16]
	movups xmm11,[rdx+3*16]
	
	movups xmm4,[rsi]
	movups xmm5,[rsi+16]
	movups xmm6,[rsi+2*16]
	movups xmm7,[rsi+3*16]
	
	movups xmm0,[rdi]
	movups xmm1,[rdi+16]
	movups xmm2,[rdi+2*16]
	movups xmm3,[rdi+3*16]
	
	mulps xmm8,xmm12
	mulps xmm9,xmm13
	mulps xmm10,xmm14
	mulps xmm11,xmm15
	subq r8,16
	lea rcx,[rcx+4*16]
	mulps xmm4,xmm8
	mulps xmm5,xmm9
	mulps xmm6,xmm10
	mulps xmm7,xmm11
	lea rdx,[rdx+4*16]
	addps xmm0,xmm4
	addps xmm1,xmm5
	addps xmm2,xmm6
	addps xmm3,xmm7
	lea rsi,[rsi+4*16]
	movups [rdi],xmm0
	movups [rdi+16],xmm1
	movups [rdi+2*16],xmm2
	movups [rdi+3*16],xmm3
	lea rdi,[rdi+4*16]
	jnz multiply3addtolp
	ret	
end asm
end sub

sub multiplyaddtoscalar naked (result as single ptr,x as single ptr,y as single,n as ulongint)
asm
	shufps XMM0,XMM0,0
	.align 16
multiplyaddtosclp:
	movups xmm1,[rsi]
	movups xmm2,[rsi+16*1]
	movups xmm3,[rsi+16*2]
	movups xmm4,[rsi+16*3]
	movups xmm5,[rdi]
	movups xmm6,[rdi+16*1]
	movups xmm7,[rdi+16*2]
	movups xmm8,[rdi+16*3]
	
	mulps xmm1,xmm0
    mulps xmm2,xmm0
    mulps xmm3,xmm0
    mulps xmm4,xmm0
    subq rdx,16
    addps xmm1,xmm5
    addps xmm2,xmm6
    addps xmm3,xmm7
    addps xmm4,xmm8
	movups [rdi],xmm1
	movups [rdi+16*1],xmm2
	movups [rdi+16*2],xmm3
	movups [rdi+16*3],xmm4
	lea rsi,[rsi+16*4]
	lea rdi,[rdi+16*4]
	jnz multiplyaddtosclp
	ret	
end asm
end sub
	
sub add naked (result as single ptr,x as single ptr,y as single ptr,n as ulongint)
asm
	subq rcx,16
	.align 16
addlp:
	movups xmm0,[rsi+4*rcx+16*3]
	movups xmm1,[rsi+4*rcx+16*2]
	movups xmm2,[rsi+4*rcx+16]
	movups xmm3,[rsi+4*rcx]
	addps xmm0,[rdx+4*rcx+16*3]
    addps xmm1,[rdx+4*rcx+16*2]
    addps xmm2,[rdx+4*rcx+16*1]
    addps xmm3,[rdx+4*rcx]
    subq rcx,16
	movups [rdi+4*rcx+64+16*3],xmm0
	movups [rdi+4*rcx+64+16*2],xmm1
	movups [rdi+4*rcx+64+16],xmm2
	movups [rdi+4*rcx+64],xmm3
	jnc addlp
	ret
end asm
end sub
	
sub subtract naked (result as single ptr,x as single ptr,y as single ptr,n as ulongint)
asm
	subq rcx,16
	.align 16
sublp:
	movups xmm0,[rsi+4*rcx+16*3]
	movups xmm1,[rsi+4*rcx+16*2]
	movups xmm2,[rsi+4*rcx+16]
	movups xmm3,[rsi+4*rcx]
	subps xmm0,[rdx+4*rcx+16*3]
    subps xmm1,[rdx+4*rcx+16*2]
    subps xmm2,[rdx+4*rcx+16*1]
    subps xmm3,[rdx+4*rcx]
    subq rcx,16
	movups [rdi+4*rcx+64+16*3],xmm0
	movups [rdi+4*rcx+64+16*2],xmm1
	movups [rdi+4*rcx+64+16],xmm2
	movups [rdi+4*rcx+64],xmm3
	jnc sublp
	ret
end asm
end sub

function sum naked (x as single ptr,n as ulongint) as single
asm
	subq rsi,16
	pxor XMM0,XMM0
	.align 16
vecsumlp:
	movups xmm1,[rdi+4*rsi+16*3]
	movups xmm2,[rdi+4*rsi+16*2]
	movups xmm3,[rdi+4*rsi+16]
	movups xmm4,[rdi+4*rsi]
	subq rsi,16
	addps XMM0,XMM1
	addps XMM0,XMM2
	addps XMM0,XMM3
	addps XMM0,XMM4
	jnc vecsumlp
	movups XMM1,XMM0
	psrldq XMM1,4
	addss XMM0,XMM1
	psrldq XMM1,4
	addss XMM0,XMM1
	psrldq XMM1,4
	addss XMM0,XMM1
	ret
end asm
end function

function sumsq naked (x as single ptr,n as ulongint) as single
asm
	subq rsi,16
	pxor XMM0,XMM0
	.align 16
veclenlp:
	movups xmm1,[rdi+4*rsi+16*3]
	movups xmm2,[rdi+4*rsi+16*2]
	movups xmm3,[rdi+4*rsi+16]
	movups xmm4,[rdi+4*rsi]
	subq rsi,16
	mulps XMM1,XMM1
	mulps XMM2,XMM2
	mulps XMM3,XMM3
	mulps XMM4,XMM4
	addps XMM0,XMM1
	addps XMM0,XMM2
	addps XMM0,XMM3
	addps XMM0,XMM4
	jnc veclenlp
	movups XMM1,XMM0
	psrldq XMM1,4
	addss XMM0,XMM1
	psrldq XMM1,4
	addss XMM0,XMM1
	psrldq XMM1,4
	addss XMM0,XMM1
	ret
end asm
end function

sub shiftsignfirst naked (result as ulong ptr,x as single ptr,n as ulongint)
	asm
	.align 16
shiftst:
	movdqu xmm0,[rsi]
	movdqu xmm1,[rsi+16]
	movdqu xmm2,[rsi+2*16]
	movdqu xmm3,[rsi+3*16]
	
	psrld xmm0,31
	psrld xmm1,31
	psrld xmm2,31
	psrld xmm3,31
	
	sub rdx,16
	lea rsi,[rsi+64]
	
	movdqu [rdi],xmm0
	movdqu [rdi+16],xmm1
	movdqu [rdi+32],xmm2
	movdqu [rdi+48],xmm3
	lea rdi,[rdi+64]
	jnz shiftst
	ret
end asm
end sub 

sub shiftsignnext naked (result as ulong ptr,x as single ptr,n as ulongint)
	asm
	.align 16
shifts:
	movdqu xmm0,[rsi]
	movdqu xmm1,[rsi+16]
	movdqu xmm2,[rsi+2*16]
	movdqu xmm3,[rsi+3*16]
	
	movdqu xmm4,[rdi]
	movdqu xmm5,[rdi+16]
	movdqu xmm6,[rdi+2*16]
	movdqu xmm7,[rdi+3*16]
	
	psrld xmm0,31
	psrld xmm1,31
	psrld xmm2,31
	psrld xmm3,31
	
	paddd xmm4,xmm4
	paddd xmm5,xmm5
	paddd xmm6,xmm6
	paddd xmm7,xmm7
	sub rdx,16
	
	paddd xmm4,xmm0
	paddd xmm5,xmm1
	paddd xmm6,xmm2
	paddd xmm7,xmm3
	lea rsi,[rsi+64]
	movdqu [rdi],xmm4
	movdqu [rdi+16],xmm5
	movdqu [rdi+32],xmm6
	movdqu [rdi+48],xmm7
	lea rdi,[rdi+64]
	jnz shifts
	ret
end asm
end sub 

sub bybitaddto naked (result as single ptr,vec as single ptr,symbols as ulong ptr,bitshift as ulong,n as ulongint)
asm	
	mov eax,0x80000000
	movd xmm9,ecx
	movd xmm8,eax
	pshufd xmm8,xmm8,0
	.align 16
bybits:
	
	movdqu xmm4,[rdx]
	movdqu xmm5,[rdx+16]
	movdqu xmm6,[rdx+2*16]
	movdqu xmm7,[rdx+3*16]
	sub r8,16
	movups xmm0,[rsi]
	movups xmm1,[rsi+16]
	movups xmm2,[rsi+2*16]
	movups xmm3,[rsi+3*16]
	
	pslld xmm4,xmm9
	pslld xmm5,xmm9
	pslld xmm6,xmm9
	pslld xmm7,xmm9
	
	pand xmm4,xmm8
	pand xmm5,xmm8
	pand xmm6,xmm8
	pand xmm7,xmm8
	
	pxor xmm0,xmm4
	pxor xmm1,xmm5
	pxor xmm2,xmm6
	pxor xmm3,xmm7
	
	movups xmm4,[rdi]
	movups xmm5,[rdi+16]
	movups xmm6,[rdi+16*2]
	movups xmm7,[rdi+16*3]
	
	addps xmm4,xmm0
	addps xmm5,xmm1
	addps xmm6,xmm2
	addps xmm7,xmm3
	
	movups [rdi],xmm4
	movups [rdi+16],xmm5
	movups [rdi+32],xmm6
	movups [rdi+48],xmm7
		
	lea rdx,[rdx+64]
	lea rsi,[rsi+64]
	lea rdi,[rdi+64]
	jnz bybits
	ret
end asm
end sub

'less than zero=-1, positive =1
sub signof naked (result as single ptr,x as single ptr, n as ulongint)
asm
	mov eax,0x3f800000
	mov ecx,0x80000000
	movd xmm4,eax
	movd xmm5,ecx
	shufps xmm4,xmm4,0
	shufps xmm5,xmm5,0
	.align 16
signoflp:
	movups xmm0,[rsi]
	movups xmm1,[rsi+16]
	movups xmm2,[rsi+16*2]
	movups xmm3,[rsi+16*3]
	subq rdx,16
	andps xmm0,xmm5
	andps xmm1,xmm5
	andps xmm2,xmm5
	andps xmm3,xmm5
	por xmm0,xmm4
	por xmm1,xmm4
	por xmm2,xmm4
	por xmm3,xmm4
	movups [rdi],xmm0
	movups [rdi+16],xmm1
	movups [rdi+16*2],xmm2
	movups [rdi+16*3],xmm3
	lea rsi,[rsi+64]
	lea rdi,[rdi+64]
	jnz signoflp
	ret
end asm
end sub

sub cdf naked (result as single ptr,x as single ptr,n as ulongint)
asm

	movaps xmm15,cdfAconst[rip]
	movaps xmm14,cdfAconst[rip+16]
	movaps xmm13,cdfAconst[rip+2*16]
	movaps xmm12,cdfAconst[rip+3*16]
	subq rdx,16
	.align 16
cdfAlp:
	movups xmm0,[rsi+4*rdx+16*3]
	movups xmm1,[rsi+4*rdx+16*2]
	movups xmm2,[rsi+4*rdx+16]
	movups xmm3,[rsi+4*rdx]
	movaps xmm4,cdfAconst[rip+9*16]
	movaps xmm8,xmm0
	movaps xmm9,xmm1
	movaps xmm10,xmm2
	movaps xmm11,xmm3
	andps xmm0,xmm15
	andps xmm1,xmm15
	andps xmm2,xmm15
	andps xmm3,xmm15
	mulps xmm0,xmm12
	mulps xmm1,xmm12
	mulps xmm2,xmm12
	mulps xmm3,xmm12
	movaps xmm5,xmm4
	movaps xmm6,xmm4
	movaps xmm7,xmm4
	mulps xmm4,xmm0
	mulps xmm5,xmm1
	mulps xmm6,xmm2
	mulps xmm7,xmm3
	addps xmm4,cdfAconst[rip+8*16]
	addps xmm5,cdfAconst[rip+8*16]
	addps xmm6,cdfAconst[rip+8*16]
	addps xmm7,cdfAconst[rip+8*16]
	mulps xmm4,xmm0
	mulps xmm5,xmm1
	mulps xmm6,xmm2
	mulps xmm7,xmm3
	addps xmm4,cdfAconst[rip+7*16]
	addps xmm5,cdfAconst[rip+7*16]
	addps xmm6,cdfAconst[rip+7*16]
	addps xmm7,cdfAconst[rip+7*16]
	mulps xmm4,xmm0
	mulps xmm5,xmm1
	mulps xmm6,xmm2
	mulps xmm7,xmm3
	addps xmm4,cdfAconst[rip+6*16]
	addps xmm5,cdfAconst[rip+6*16]
	addps xmm6,cdfAconst[rip+6*16]
	addps xmm7,cdfAconst[rip+6*16]
	mulps xmm4,xmm0
	mulps xmm5,xmm1
	mulps xmm6,xmm2
	mulps xmm7,xmm3
	addps xmm4,cdfAconst[rip+5*16]
	addps xmm5,cdfAconst[rip+5*16]
	addps xmm6,cdfAconst[rip+5*16]
	addps xmm7,cdfAconst[rip+5*16]
	mulps xmm4,xmm0
	mulps xmm5,xmm1
	mulps xmm6,xmm2
	mulps xmm7,xmm3
	addps xmm4,cdfAconst[rip+4*16]
	addps xmm5,cdfAconst[rip+4*16]
	addps xmm6,cdfAconst[rip+4*16]
	addps xmm7,cdfAconst[rip+4*16]
	mulps xmm4,xmm0
	mulps xmm5,xmm1
	mulps xmm6,xmm2
	mulps xmm7,xmm3
	addps xmm4,xmm13
	addps xmm5,xmm13
	addps xmm6,xmm13
	addps xmm7,xmm13
	
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	mulps xmm7,xmm7
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	mulps xmm7,xmm7
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	mulps xmm7,xmm7
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	mulps xmm7,xmm7
	
	movaps xmm0,xmm13
	movaps xmm1,xmm13
	movaps xmm2,xmm13
	movaps xmm3,xmm13
	
	divps xmm0,xmm4
	divps xmm1,xmm5
	divps xmm2,xmm6
	divps xmm3,xmm7
	subq rdx,16
	
	andps xmm8,xmm14
	andps xmm9,xmm14
	andps xmm10,xmm14
	andps xmm11,xmm14
	movaps xmm4,xmm13
	movaps xmm5,xmm13
	movaps xmm6,xmm13
	movaps xmm7,xmm13
	
	subps xmm4,xmm0
	subps xmm5,xmm1
	subps xmm6,xmm2
	subps xmm7,xmm3
	orps xmm4,xmm8
	orps xmm5,xmm9
	orps xmm6,xmm10
	orps xmm7,xmm11
	
	movups [rdi+4*rdx+64+16*3],xmm4
	movups [rdi+4*rdx+64+16*2],xmm5
	movups [rdi+4*rdx+64+16],xmm6
	movups [rdi+4*rdx+64],xmm7

	jnc cdfAlp
	ret
	.align 16
cdfAconst:
	.int 0x7fffffff,0x7fffffff,0x7fffffff,0x7fffffff
	.int 0x80000000,0x80000000,0x80000000,0x80000000
	.float 1,1,1,1
	.float 0.707106781,0.707106781,0.707106781,0.707106781
	.float 0.0705230784,0.0705230784,0.0705230784,0.0705230784
	.float 0.0422820123,0.0422820123,0.0422820123,0.0422820123
	.float 0.0092705272,0.0092705272,0.0092705272,0.0092705272
	.float 0.0001520143,0.0001520143,0.0001520143,0.0001520143
	.float 0.0002765672,0.0002765672,0.0002765672,0.0002765672
	.float 0.0000430638,0.0000430638,0.0000430638,0.0000430638
end asm
end sub

'vec array should contain bits*n elements
sub getSymbols(symbols as ulong ptr,vecarray as single ptr,bits as ulong,n as ulongint) 
	shiftsignfirst(symbols,vecarray,n)
	for i as ulong=1 to bits-1
		shiftsignnext(symbols,vecarray+i*n,n)
	next
end sub

sub filterBySymbols(result as single ptr,vecarray as single ptr,symbols as ulong ptr,bits as ulong,n as ulong)
	zero(result,n)
	for i as ulong=0 to bits-1
		bybitaddto(result,vecarray+i*n,symbols,32-bits+i,n)
	next
end sub

'highest set bit, undefined if x=0
function bitscanreverse naked (x as ulong) as ulong
	asm
	bsr eax,edi
	ret
	end asm
end function

sub adjust(result as single ptr,x as single ptr,n as ulongint)
	var vl=sqr(sumsq(x,n)/n)
	if vl<1e-30 then 
		signof(result,x,n)
	else
		multiplyscalar(result,x,1#/vl,n)
	end if
end sub

'Random projection from x to result.  result_n must be a power of 2
'zero result before calling if you need to
sub hashReduceAppend(result as single ptr,x as single ptr,h as ulongint,result_n as ulongint,x_n as ulongint)
	var shift=63-bitscanreverse(result_n-1)
	for i as ulongint=0 to x_n-1
		var x1=x[i]
		h+=&h3C6EF372FE94F82CULL
		h*=&h9E3779B97F4A7C15ULL
		result[h shr shift]+=x1
	next 
end sub	

' preserve sign
sub signedsqrt naked (result as single ptr,x as single ptr,n as ulongint)
asm
	mov ecx,0x7fffffff
	movd xmm9,ecx
	pshufd xmm9,xmm9,0
	mov ecx,0x80000000
	movd xmm10,ecx
	pshufd xmm10,xmm10,0
	.align 16
signedsqrlp:
	movups xmm0,[rsi]
	movups xmm1,[rsi+16]
	movups xmm2,[rsi+2*16]
	movups xmm3,[rsi+3*16]
	subq rdx,16
	lea rsi,[rsi+4*16]
	movaps xmm4,xmm0
	movaps xmm5,xmm1
	movaps xmm6,xmm2
	movaps xmm7,xmm3
	andps xmm0,xmm9
    andps xmm1,xmm9
    andps xmm2,xmm9
    andps xmm3,xmm9
    andps xmm4,xmm10
    andps xmm5,xmm10
    andps xmm6,xmm10
    andps xmm7,xmm10
    sqrtps xmm0,xmm0
    sqrtps xmm1,xmm1
    sqrtps xmm2,xmm2
    sqrtps xmm3,xmm3
    orps xmm0,xmm4
    orps xmm1,xmm5
    orps xmm2,xmm6
    orps xmm3,xmm7
	movups [rdi],xmm0
	movups [rdi+16],xmm1
	movups [rdi+2*16],xmm2
	movups [rdi+3*16],xmm3
	lea rdi,[rdi+4*16]
	jnz signedsqrlp
	ret
end asm
end sub

'preserve sign, approximate
sub signedsqrtapproximate naked (result as single ptr,x as single ptr,n as ulongint)
asm
	mov ecx,0x7fffffff
	movd xmm9,ecx
	pshufd xmm9,xmm9,0
	mov ecx,0x80000000
	movd xmm10,ecx
	pshufd xmm10,xmm10,0
	mov ecx,0x3f800000
	movd xmm11,ecx
	pshufd xmm11,xmm11,0
	.align 16
signedsqrapplp:
	movdqu xmm0,[rsi]
	movdqu xmm1,[rsi+16]
	movdqu xmm2,[rsi+2*16]
	movdqu xmm3,[rsi+3*16]
	subq rdx,16
	lea rsi,[rsi+4*16]
	movdqa xmm4,xmm0
	movdqa xmm5,xmm1
	movdqa xmm6,xmm2
	movdqa xmm7,xmm3
	pand xmm0,xmm9
    pand xmm1,xmm9
    pand xmm2,xmm9
    pand xmm3,xmm9
    pand xmm4,xmm10
    pand xmm5,xmm10
    pand xmm6,xmm10
    pand xmm7,xmm10
    paddd xmm0,xmm11
    paddd xmm1,xmm11
    paddd xmm2,xmm11
    paddd xmm3,xmm11
    psrld xmm0,1
    psrld xmm1,1
    psrld xmm2,1
    psrld xmm3,1
    por xmm0,xmm4
    por xmm1,xmm5
    por xmm2,xmm6
    por xmm3,xmm7
	movdqu [rdi],xmm0
	movdqu [rdi+16],xmm1
	movdqu [rdi+2*16],xmm2
	movdqu [rdi+3*16],xmm3
	lea rdi,[rdi+4*16]
	jnz signedsqrapplp
	ret
end asm
end sub

sub	truncate naked (result as single ptr,x as single ptr,loboff as single,n as ulongint)
asm
	subq rdx,16
	shufps xmm0,xmm0,0
	xorps xmm1,xmm1
	subps xmm1,xmm0
	.align 16
truncatelp:
	movups xmm2,[rsi+4*rdx+16*3]
	movups xmm3,[rsi+4*rdx+16*2]
	movups xmm4,[rsi+4*rdx+16]
	movups xmm5,[rsi+4*rdx]
	subq rdx,16
	movaps xmm6,xmm2
	movaps xmm7,xmm3
	movaps xmm8,xmm4
	movaps xmm9,xmm5
	maxps xmm2,xmm1
	maxps xmm3,xmm1
	maxps xmm4,xmm1
	maxps xmm5,xmm1
	minps xmm2,xmm0
	minps xmm3,xmm0
	minps xmm4,xmm0
	minps xmm5,xmm0
	subps xmm6,xmm2
	subps xmm7,xmm3
	subps xmm8,xmm4
	subps xmm9,xmm5
	movups [rdi+4*rdx+64+16*3],xmm6
	movups [rdi+4*rdx+64+16*2],xmm7
	movups [rdi+4*rdx+64+16],xmm8
	movups [rdi+4*rdx+64],xmm9
	jnc truncatelp
	ret
end asm 
end sub

end namespace
