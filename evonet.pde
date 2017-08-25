ENet enet=new ENet(64, 5, 3, 10000);
float[][] targets=new float[20][64];
float[][] inputs=new float[20][64];
float[] x=new float[64];
float oldCost=1e38f;

void setup() {
  for (int i=0; i<targets.length; i++) {
    for (int j=0; j<x.length; j++) {
      inputs[i][j]=j%(i+2);
      targets[i][j]=0.05f*(j%(i+3));
    }
  }
  while (oldCost>3) {
    enet.train(targets, inputs);
    float c=enet.getCost();
    if (c<oldCost) {
      oldCost=c;
      println(c);
    }
  }
  enet.recall(x, inputs[19]);
  for (int i=0; i<x.length; i++) {
    println(targets[19][i]+"     "+x[i]);
  }
}