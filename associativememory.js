// Associative memory done in javascript for some reason!
// I'll maybe translate the ENet class later.
// I think with very small training sets the density has to be excessively large
// how ever with larger training sets any binary granularity issues should go away. 
      
        var r=[];
        var s=[];
        var x =[];
        var y =[];
        var u =[];
        var v=[];
        var res=[];
        
        var n=32;
		var am=new AM(n,10,0);
        
        for (var i = 0; i <n ; i++) {
            r[i]=i%2;
			s[i]=i%3;
			x [i]=i%4;
			y [i]=i%5;
			u [i]=i%6;
			v[i]=i%7;
        }
        for(var i=0;i<30;i++){
			am.trainVec(s,r);
			am.trainVec(y,x);
			am.trainVec(v,u);
		}
		am.recallVec(res,x);
		for (var i = 0; i <n ; i++) {
			console.log(y[i]+"      "+res[i]);
        }
       
        
        

       
// vecLen must be 2,4,8,16,32.....       
function AM(vecLen,density,hash){
	this.rp=new RP();
	this.vecLen=vecLen;
	this.density=density;
	this.hash=hash;
	this.weights=[];
    this.bipolar=[];
    this.workA=[];
    this.workB=[];
    
    this.recallVec=function(resultVec,inVec){
		var wtIdx=0;
		this.rp.copy(this.workA,inVec);
		this.rp.fillFloat(resultVec,this.vecLen);
		for(var i=0;i<this.density;i++){
			this.rp.fastRP(this.workA,this.hash+i);
			for(var j=0;j<this.vecLen;j++){
				if(this.workA[j]<0.0){
					this.bipolar[wtIdx]=-1.0;
					resultVec[j]-=this.weights[wtIdx];
				}else{
					this.bipolar[wtIdx]=1.0;
					resultVec[j]+=this.weights[wtIdx];
				}
				wtIdx++;
			}
		}		
	}	
    
    this.trainVec=function(targetVec,inVec){
		var rate=1.0/density;
		var wtIdx=0;
		this.recallVec(this.workB, inVec);
		this.rp.subtract(this.workB,targetVec,this.workB);
		for(var i=0;i<this.density;i++){
			for(var j=0;j<this.vecLen;j++){
				this.weights[j+wtIdx]+=this.bipolar[j+wtIdx]*this.workB[j]*rate;
			}
			wtIdx+=this.vecLen;
		}	
    }	
    
    this.rp.fillFloat(this.weights,vecLen*density);
    this.rp.fillFloat(this.bipolar,vecLen*density);
    this.rp.fillFloat(this.workA,vecLen);
    this.rp.fillFloat(this.workB,vecLen);	
    
}	

function RP(){

        this.wht=function(vec) {
            var n = vec.length;
            var hs = 1;
            while (hs < n) {
                var i = 0;
                while (i < n) {
                    var j = i + hs;
                    while (i < j) {
                        var a = vec[i];
                        var b = vec[i + hs];
                        vec[i] = a + b;
                        vec[i + hs] = a - b;
                        i += 1;
                    }
                    i += hs;
                }
                hs += hs;
            }
            this.scale(vec,vec, 1.0 / Math.sqrt(n));
        }

       this.signFlip =function(vec, hash) {
            for (var i = 0, n = vec.length; i < n; i++) {
				hash+=1013904223;
				hash*=1664525;
				hash&=0xffffffff;
				hash+=1013904223;
				hash*=1664525;
				hash&=0xffffffff;
                if ((hash & 0x80000000)===0) {
                    vec[i] = -vec[i];
                }
            }
        }
        
        this.fastRP=function(vec,hash){
			this.signFlip(vec,hash);
			this.wht(vec);
		}

        this.scale=function(rVec,xVec, sc) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                rVec[i] =xVec[i]*sc;
            }
        }

        this.multiply=function(rVec, xVec, yVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                rVec[i] = xVec[i] * yVec[i];
            }
        }

        this.multiplyAddTo=function (rVec, xVec, yVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                rVec[i] += xVec[i] * yVec[i];
            }
        }

        // x-y
        this.subtract=function(rVec, xVec, yVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                rVec[i] = xVec[i] - yVec[i];
            }
        }

        this.add=function (rVec, xVec, yVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                rVec[i] = xVec[i] + yVec[i];
            }
        }

        // converts each element of xVec to +1 or -1 according to its sign.
        this.signOf=function(rVec, xVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                if (xVec[i] < 0.0) {
                    rVec[i] = -1.0;
                } else {
                    rVec[i] = 1.0;
                }
            }
        }

        this.truncate=function(rVec, xVec, t) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                var tt = Math.abs(xVec[i]) - t;
                if (tt < 0.0) {
                    rVec[i] = 0.0;
                    continue;
                }
                if (xVec[i] < 0.0) {
                    rVec[i] = -tt;
                } else {
                    rVec[i] = tt;
                }
            }
        }

       this.sumSq= function (vec) {
            var sum = 0.0;
            for (var i = 0, n = vec.length; i < n; i++) {
                sum += vec[i] * vec[i];
            }
            return sum;
        }

        // Assuming each elememt of is from a Gaussian distribution of zero mean
        // adjust the variance of each element to 1.				
        this.adjust=function(rVec, xVec) {
            var MIN_SQ = 1e-20;
            var adj = 1.0 / Math.sqrt((this.sumSq(xVec) / xVec.length) + MIN_SQ);
            this.scale(rVec, xVec, adj);
        }
        
        this.copy=function(rVec, xVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
               rVec[i]=xVec[i];
            }
        }
        
        this.fillFloat=function(rVec, n) {
            for (var i = 0; i < n; i++) {
               rVec[i]=0.0;
            }
        }
}