#include "wht14.bas"
#include "xfile.bas"
#include "rnd.bas"
' FreeBasic 1.05 Linux AMD64 only.
' Associative memory type
type AM
	veclen as ulongint
	density as ulongint
	hash as ulongint
	wts as single ptr
	surface as single ptr
	workA as single ptr
	workB as single ptr
	workC as single ptr
	declare sub init(veclen as ulong,density as ulong,hash as ulong=0)
	declare sub free()
	declare function sizememory() as boolean
	declare sub save()
	declare sub load()
	declare sub recall(result as single ptr,invec as single ptr)
	declare sub recallSurface(result as single ptr,invec as single ptr)
	declare sub train(target as single ptr,invec as single ptr)
end type

'returns true on error
function AM.sizememory() as boolean
	var w=reallocate(wts,veclen*density*sizeof(single))
	var s=reallocate(surface,veclen*density*sizeof(single))
	var a=reallocate(workA,veclen*sizeof(single))
	var b=reallocate(workB,veclen*sizeof(single))
	var c=reallocate(workC,veclen*sizeof(single))
	if w=0 or s=0 or a=0 or b=0 or c=0 then return true
	wts=w
	surface=s
	workA=a
	workB=b
	workC=c
	return false
end function

sub AM.init(veclen as ulong,density as ulong,hash as ulong=0)
	this.veclen=veclen
	this.density=density
	this.hash=hash
	sizememory()
	rp.zero(wts,veclen*density)
end sub

sub AM.free()
	deallocate(wts)
	deallocate(surface)
	deallocate(workA)
	deallocate(workB)
	deallocate(workC)
	wts=0
	surface=0
	workA=0
	workB=0
	workC=0
end sub

'use xfile openfile(...) and closefile() for operation, error flag in xfile
sub AM.save()
	xfile.save(veclen)
	xfile.save(density)
	xfile.save(hash)
	xfile.save(wts,veclen*density)
end sub

'signals error through xfile.fileerror
sub AM.load()
	xfile.load(veclen)
	xfile.load(density)
	xfile.load(hash)
	if xfile.fileerror then return
	if sizememory() then
		xfile.seterror()
		return 
	end if
	xfile.load(wts,veclen*density)
end sub

sub AM.recall(result as single ptr,invec as single ptr)
	dim as single ptr wtidx=wts
	dim as ulongint h=hash
	rp.copy(workA,invec,veclen)
	rp.zero(result,veclen)
	for i as ulongint=0 to density-1
		rp.hashflipA(workA,workA,h,veclen)
		rp.wht(workA,veclen)
		rp.signof(workB,workA,veclen)	'This is usually enough of a nonlinearity to split
		rp.multiplyaddto(result,workB,wtidx,veclen) 'the response to close by inputs.
		h+=1
		wtidx+=veclen
	next
	rp.wht(result,veclen) 	'spreading mechanism allowing you to use a subset of the 
end sub						'output dimensions more effectively.

sub AM.recallSurface(result as single ptr,invec as single ptr)
	dim as single ptr wtidx=wts,suridx=surface
	dim as ulongint h=hash
	rp.copy(workA,invec,veclen)
	rp.zero(result,veclen)
	for i as ulongint=0 to density-1
		rp.hashflipA(workA,workA,h,veclen)
		rp.wht(workA,veclen)
		rp.signof(workB,workA,veclen)
		rp.copy(suridx,workB,veclen)
		rp.multiplyaddto(result,workB,wtidx,veclen)
		h+=1
		wtidx+=veclen
		suridx+=veclen
	next
	rp.wht(result,veclen)
end sub

sub AM.train(target as single ptr,invec as single ptr)
	dim as single ptr wtidx=wts,suridx=surface
	recallSurface(workC,invec)
	rp.subtract(workC,target,workC,veclen)
	rp.multiplyscalar(workC,workC,1!/density,veclen)
	rp.wht(workC,veclen)
	for i as ulongint=0 to density-1
		rp.multiplyaddto(wtidx,workC,suridx,veclen)
		wtidx+=veclen
		suridx+=veclen
	next
end sub

' Deep random projection neural network
type ENet
	veclen as ulongint
	density as ulongint
	depth as ulongint
	precision as ulongint
	hash as ulongint
	wts as single ptr
	mwts as single ptr
	workA as single ptr
	workB as single ptr
	workC as single ptr
	workD as single ptr
	parentCost as single
	declare sub init(veclen as ulong,density as ulong,depth as ulong,precision as ulong,hash as ulong=0)
	declare sub free()
	declare function sizememory() as boolean
	declare sub save()
	declare sub load()
	declare sub recall(result as single ptr,invec as single ptr)
	declare sub train(targets as single ptr,invecs as single ptr,examples as ulong)
end type

'returns true on error
function ENet.sizememory() as boolean
	var w=reallocate(wts,veclen*density*depth*sizeof(single))
	var m=reallocate(mwts,veclen*density*depth*sizeof(single))
	var a=reallocate(workA,veclen*sizeof(single))
	var b=reallocate(workB,veclen*sizeof(single))
	var c=reallocate(workC,veclen*sizeof(single))
	var d=reallocate(workD,veclen*sizeof(single))
	if w=0 or m=0 or a=0 or b=0 or c=0 or d=0 then return true
	wts=w
	mwts=m
	workA=a
	workB=b
	workC=c
	workD=d
	return false
end function

sub ENet.init(veclen as ulong,density as ulong,depth as ulong,precision as ulong,hash as ulong=0)
	this.veclen=veclen
	this.density=density
	this.depth=depth
	this.precision=precision
	this.hash=hash
	sizememory()
	for i as ulongint=0 to veclen*density*depth-1
		wts[i]=xor128.rndSingleSym()
	next
	parentCost=1!/0!
end sub

sub ENet.free()
	deallocate(wts)
	deallocate(mwts)
	deallocate(workA)
	deallocate(workB)
	deallocate(workC)
	deallocate(workD)
	wts=0
	mwts=0
	workA=0
	workB=0
	workC=0
	workC=0
end sub

'use xfile openfile(...) and closefile() for operation, error flag in xfile
sub ENet.save()
	xfile.save(veclen)
	xfile.save(density)
	xfile.save(depth)
	xfile.save(precision)
	xfile.save(hash)
	xfile.save(parentCost)
	xfile.save(wts,veclen*density*depth)
end sub

'signals error through xfile.fileerror
sub ENet.load()
	xfile.load(veclen)
	xfile.load(density)
	xfile.load(depth)
	xfile.load(precision)
	xfile.load(hash)
	xfile.load(parentCost)
	if xfile.fileerror then return
	if sizememory() then
		xfile.seterror()
		return 
	end if
	xfile.load(wts,veclen*density*depth)
end sub

sub ENet.recall(result as single ptr,invec as single ptr)
	dim as single ptr wtidx=wts
	dim as ulongint h=hash
	rp.adjust(workA,invec,veclen)
	for j as ulongint=0 to depth-1	
		rp.zero(result,veclen)
		rp.copy(workB,workA,veclen)
		for i as ulongint=0 to density-1
			rp.hashflipA(workA,workA,h,veclen)
			rp.wht(workA,veclen)
			rp.hashflipB(workB,workB,h,veclen)
			rp.wht(workB,veclen)
			rp.multiply(workC,workA,workB,veclen)
			rp.hashflipA(workC,workC,not h,veclen)
			rp.wht(workC,veclen)
			rp.multiplyaddto(result,workC,wtidx,veclen)
			wtidx+=veclen
			h+=1
		next
		if j=depth-1 then exit for
		rp.adjust(workA,result,veclen)
	next
	rp.wht(result,veclen)	'you could comment this line out
end sub

sub ENet.train(targets as single ptr,invecs as single ptr,examples as ulong)
	dim as single ccost
	for i as ulongint=0 to veclen*density*depth-1
		mwts[i]=Xor128.mutateSingleSym(wts[i],precision)
	next
	swap wts,mwts
	for i as ulongint=0 to examples-1
		recall(workD,invecs+i*veclen)
		rp.subtract(workD,workD,targets+i*veclen,veclen)
		ccost+=rp.sumsq(workD,veclen)
	next
	if ccost<parentCost then
		parentCost=ccost
	else
		swap wts,mwts
	end if		
end sub
			

		
	



