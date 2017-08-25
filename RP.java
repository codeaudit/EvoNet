// Class for fast random projections using the Walsh Hadamard Transform (WHT.)

class RP {

  final static float MIN_SQ=1e-20f;  
  Xor128 sfRnd=new Xor128();

  // Flip the sign of each element of vec according to a 
  // pseudorandom sequence determined by h.
  void signFlip(float[] vec, long h) {
    sfRnd.setSeed(h);
    for (int i=0; i<vec.length; i++) {
      int x=(int)sfRnd.nextLong()&0x80000000;  // select sign flag bit
      vec[i]=Float.intBitsToFloat(x^Float.floatToRawIntBits(vec[i]));  // xor
    }
  }

  // Fast random projection of vec  
  // See: https://drive.google.com/open?id=0BwsgMLjV0BnhOGNxOTVITHY1U28
  void fastRP(float[] vec, long h) {
    signFlip(vec, h);
    wht(vec);
  }

  // Fast WHT, vec.length must be (2,4,8,16,32.....)
  // See: https://en.wikipedia.org/w/index.php?title=Fast_Walsh%E2%80%93Hadamard_transform&oldid=784533260
  static void wht(float[] vec) {
    int i, j, hs=1, n=vec.length;
    while (hs<n) {
      i=0;
      while (i<n) {
        j=i+hs;
        while (i<j) {
          float a=vec[i];
          float b=vec[i+hs];
          vec[i]=a+b;
          vec[i+hs]=a-b;
          i+=1;
        }
        i+=hs;
      }
      hs+=hs;
    }
    scale(vec, vec, 1f/(float)Math.sqrt(n));
  }

  static void multiply(float[] rVec, float[] x, float[] y) {
    for (int i=0; i<rVec.length; i++) {
      rVec[i]=x[i]*y[i];
    }
  } 

  static void multiplyAddTo(float[] rVec, float[] x, float[] y) {
    for (int i=0; i<rVec.length; i++) {
      rVec[i]+=x[i]*y[i];
    }
  } 

  // x-y
  static void subtract(float[] rVec, float[] x, float[] y) {
    for (int i=0; i<rVec.length; i++) {
      rVec[i]=x[i]-y[i];
    }
  } 

  static void add(float[] rVec, float[] x, float[] y) {
    for (int i=0; i<rVec.length; i++) {
      rVec[i]=x[i]+y[i];
    }
  } 

  static void scale(float[] rVec, float[] x, float s) {
    for (int i=0; i<rVec.length; i++) {
      rVec[i]=x[i]*s;
    }
  }

  // converts each element of x to +1 or -1 according to its sign.
  static void signOf(float[] biVec, float[] x ) {
    int one=Float.floatToRawIntBits(1f);
    for (int i=0; i<biVec.length; i++) {
      biVec[i]=Float.intBitsToFloat(one|(Float.floatToRawIntBits(x[i])&0x80000000));
    }
  }

  // reduce the magnitude by t, if the magnitude is reduced below 0 it is made 0.
  // with t=1, 1.5 becomes 0.5, -2.5 becomes -1.5, .9 becomes 0 etc.
  static void truncate(float[] rVec, float[] x, float t) {
    for (int i=0; i<rVec.length; i++) {
      int f=Float.floatToRawIntBits(x[i]);
      int s=f&0x80000000;  // get sign bit
      float m=Float.intBitsToFloat(f&0x7fffffff)-t; //abs(x[i])-t
      if (m<0f) m=0f;
      rVec[i]=Float.intBitsToFloat(Float.floatToRawIntBits(m)|s); // put sign back in
    }
  }

  static float sumSq(float[] vec) {
    float sum=0f;
    for (int i=0; i<vec.length; i++) {
      sum+=vec[i]*vec[i];
    }
    return sum;
  }

  // Assuming each elememt of is from a Gaussian distribution of zero mean
  // adjust the variance of each element to 1.
  static void adjust(float[] rVec, float[] x) {    
    float adj=1f/(float)Math.sqrt((sumSq(x)/x.length)+MIN_SQ);
    scale(rVec, x, adj);
  }
}