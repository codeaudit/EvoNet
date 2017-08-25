// Random number generator xoroshiro128+ http://xoroshiro.di.unimi.it/

class Xor128 {

  private long s0;
  private long s1;

  Xor128() {
    setSeed(System.nanoTime());
  }

  public long nextLong() {
    final long s0 = this.s0;
    long s1 = this.s1;
    final long result = s0 + s1;
    s1 ^= s0;
    this.s0 = Long.rotateLeft(s0, 55) ^ s1 ^ s1 << 14;
    this.s1 = Long.rotateLeft(s1, 36);
    return result;
  }

  public float nextFloat() {
    return (nextLong()&0x7FFFFFFFFFFFFFFFL)*1.0842021e-19f;
  }

  public float nextFloatSym() {
    return nextLong()*1.0842021e-19f;
  }

  public boolean nextBoolean() {
    return nextLong() < 0;
  }

  // Mutation between -1 and 1 
  //See: https://drive.google.com/open?id=0BwsgMLjV0BnhR2h6WWpNeVJpS00
  public float mutate(long precision) {
    long ra=nextLong();
    int e=126-(int)(((ra>>>32)*precision)>>>32);
    if (e<0) return 0f;
    return Float.intBitsToFloat((e<<23)|((int)ra&0x807fffff));
  }

  // For parameters x>=0, x<=1
  public float mutateX(float x, long precision) {
    float mx=x+mutate(precision);
    if (mx>1f) return x;
    if (mx<0f) return x;
    return mx;
  }

  // For parameters x>=-1, x<=1
  public float mutateXSym(float x, long precision) {
    float mx=x+2f*mutate(precision);
    if (mx>1f) return x;
    if (mx<-1f) return x;
    return mx;
  }

  public void setSeed(long seed ) {
    s0 = seed*0xBB67AE8584CAA73BL;
    s1 = ~seed*0x9E3779B97F4A7C15L;
    nextLong();
  }
}