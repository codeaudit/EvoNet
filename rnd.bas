
' Hash function Stafford Mix 13
function hash64(h as ulongint) as ulongint
  	h = ( h xor ( h shr 30 ) ) * &hBF58476D1CE4E5B9 
    h = ( h xor ( h shr 27 ) ) * &h94D049BB133111EB
	return h xor ( h shr 31 )
end function

' Read the time stamp counter (x86-64) in a messed up way
function timestamp naked() as ulongint
	asm 
	  rdtsc
	  add rdx,rax
	  bswapq rdx
	  or rax,rdx
	  ret
	end asm
end function

namespace xor128

   dim as ulongint a,b   
   
   function rand() as ulongint
      dim as ulongint result=a+b
      b xor=a
      a=((a shl 55) or (a shr (64-55))) xor b xor (b shl 14)
      b=(b shl 36) or (b shr (64-36))
      return result
   end function
   
   sub seed(s as ulongint)
      a=hash64(s)
      b=hash64(not s)
   end sub
   
   sub init() constructor
	  seed(timestamp())
   end sub
   
	function rndConvert naked (r as ulongint,bound as ulongint) as ulongint
		asm
		   movq rax,rdi
		   mulq rsi
		   movq rax,rdx
		   ret
		end asm
	end function
		
	'ulongint between [0,top]. Includes 0 and top (top not equal max ulongint value)
	function rndInt overload (top as ulongint) as ulongint
		return rndConvert(rand(),top+1)
	end function

	'longint between [min,max]. Includes min and max
	function rndInt overload (min as longint,max as longint) as longint
		return rndConvert(rand(),max-min+1)+min
	end function


	'ulongint between [0,bound). Excludes bound
	function rndIntEx overload (bound as ulongint) as ulongint
		return rndConvert(rand(),bound)
	end function

	'long between [min,bound). Includes min, excludes bound
	function rndIntEx overload (min as longint,bound as longint) as longint
		return rndConvert(rand(),bound-min)+min
	end function

	function rndSingle() as single
		return rand()*5.4210107e-20!
	end function

	function rndSingleSym() as single
		return cast(longint,rand())*1.0842021e-19!
	end function
	
	
	function mutateSingle(precision as longint) as single	
		dim as longint e=126-rndInt(precision)
		if e<0 then return 0!
		e shl=23
		dim as ulong m=rand()
		m and=&h007fffff
		m or=e
		return *cast(single ptr,@m)
	end function

	'x=-1 to 1
	function mutateSingleSym(x as single,precision as longint) as single	
		dim as longint e=127-rndInt(precision)
		if e<0 then return x
		e shl=23
		dim as ulong m=rand()
		m and=&h807fffff
		m or=e
		dim as single v=x+*cast(single ptr,@m)
		if v>=1! then return x
		if v<=-1! then return x
		return v
	end function
	
	sub rndPermute(x() as ulong)
		dim as ulong top=ubound(x)
		for i as ulong=0 to top-1
			swap x(i),x(rndInt(i,top))
		next
	end sub

end namespace
