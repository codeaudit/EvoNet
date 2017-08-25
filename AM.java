// Associative Memory class

class AM {

  int vecLen;
  int density;
  long hash;
  float[][] weights;
  float[][] bipolar;
  float[] workA;
  float[] workB;
  RP rp;

  // vecLen must be 2,4,8,16,32.....
  AM(int vecLen, int density) {
    this.vecLen=vecLen;
    this.density=density;
    hash=new Xor128().nextLong();
    weights=new float[density][vecLen];
    bipolar=new float[density][vecLen];
    workA=new float[vecLen];
    workB=new float[vecLen];
    rp=new RP();
  }

  void recallVec(float[] resultVec, float[] inVec) {
    System.arraycopy(inVec, 0, workA, 0, vecLen);
    java.util.Arrays.fill(resultVec, 0f);
    for (int i=0; i<density; i++) {
      rp.fastRP(workA, hash+i);
      rp.signOf(bipolar[i], workA);
      rp.multiplyAddTo(resultVec, weights[i], bipolar[i]);
    }
  }

  void trainVec(float[] targetVec, float[] inVec) {
    float rate=1f/density;
    recallVec(workB, inVec);
    for (int i=0; i<vecLen; i++) {
      workB[i]=(targetVec[i]-workB[i])*rate;
    }
    for (int i=0; i<density; i++) {
      rp.multiplyAddTo(weights[i], workB, bipolar[i]);
    }
  }
}  