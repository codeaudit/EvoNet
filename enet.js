// Evolve a deep random projection neural network.

    var r = [];
    var s = [];
    var x = [];
    var y = [];
    var u = [];
    var v = [];
    var res = [];

    var n = 32;
    var enet = new ENet(n, 3, 3, 500.0);

    for (var i = 0; i < n; i++) {
        r[i] = i % 2;
        s[i] = i % 3;
        x [i] = i % 4;
        y [i] = i % 5;
        u [i] = i % 6;
        v[i] = i % 7;
    }
    var tar = [s, y, v];	//collect example pairs into arrays.
    var inp = [r, x, u];
    var oldCost = enet.parentCost;
    for (var i = 0; i < 100000; i++) {
        enet.train(tar, inp);
        if (enet.parentCost < oldCost) {
            oldCost = enet.parentCost;
            console.log(oldCost);
        }
    }
    enet.recall(res, x);
    console.log(" ");
    for (var i = 0; i < n; i++) {
        console.log(y[i] + "    " + res[i]);
    }



// vecLen must be 2,4,8,16,32.....       
    function ENet(vecLen, density, depth, precision) {
        this.rp = new RP();
        this.vecLen = vecLen;
        this.density = density;
        this.depth = depth;
        this.precision = precision;
        this.hash = Math.floor(0xffffffff * Math.random());
        this.weights = [];
        this.mWeights = [];
        this.workA = [];
        this.workB = [];
        this.workC = [];
        this.workD = [];
        this.parentCost = Number.POSITIVE_INFINITY;

        this.recall = function (resultVec, inVec) {
            var h = this.hash;
            var wtIdx = 0;
            this.rp.adjust(this.workA, inVec);
            for (var i = 0; true; i++) {
                this.rp.copy(this.workB, this.workA);
                this.rp.fillFloat(resultVec, this.vecLen);
                for (var j = 0; j < density; j++) {
                    this.rp.fastRP(this.workA, h++);
                    this.rp.fastRP(this.workB, h++);
                    this.rp.multiply(this.workC, this.workA, this.workB);
                    this.rp.fastRP(this.workC, h++);
                    for (var k = 0; k < this.vecLen; k++) {
                        resultVec[k] += this.workC[k] * this.weights[wtIdx++];
                    }
                }
                if (i === this.depth - 1)
                    break;
                this.rp.adjust(this.workA, resultVec);
            }
        }


        this.train = function (targetVecs, inVecs) {
            for (var i = 0, n = this.weights.length; i < n; i++) {
                var m = 2.0 * Math.exp(-this.precision * Math.random());
                if (Math.random() < 0.5)
                    m = -m;
                var x = this.weights[i] + m;
                if ((x > 1.0) || (x < -1.0))
                    x = this.weights[i];
                this.mWeights[i] = x;
            }
            var t = this.weights;
            this.weights = this.mWeights;
            this.mWeights = t;
            var cCost = 0.0;
            for (var i = 0, n = targetVecs.length; i < n; i++) {
                this.recall(this.workD, inVecs[i]);
                this.rp.subtract(this.workD, targetVecs[i], this.workD);
                cCost += this.rp.sumSq(this.workD);
            }
            if (cCost <= this.parentCost) {
                this.parentCost = cCost;
            } else {
                t = this.weights;
                this.weights = this.mWeights;
                this.mWeights = t;
            }
        }


        for (var i = 0, n = vecLen * density * depth; i < n; i++) {
            this.weights[i] = 1 - 2.0 * Math.random();
        }
        this.rp.fillFloat(this.mWeights, vecLen * density * depth);
        this.rp.fillFloat(this.workA, vecLen);
        this.rp.fillFloat(this.workB, vecLen);
        this.rp.fillFloat(this.workC, vecLen);
        this.rp.fillFloat(this.workD, vecLen);


    }

    function RP() {

        this.wht = function (vec) {
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
            this.scale(vec, vec, 1.0 / Math.sqrt(n));
        }

        this.signFlip = function (vec, hash) {
            for (var i = 0, n = vec.length; i < n; i++) {
                hash += 1013904223;
                hash *= 1664525;
                hash &= 0xffffffff;
                hash += 1013904223;
                hash *= 1664525;
                hash &= 0xffffffff;
                if ((hash & 0x80000000) === 0) {
                    vec[i] = -vec[i];
                }
            }
        }

        this.fastRP = function (vec, hash) {
            this.signFlip(vec, hash);
            this.wht(vec);
        }

        this.scale = function (rVec, xVec, sc) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                rVec[i] = xVec[i] * sc;
            }
        }

        this.multiply = function (rVec, xVec, yVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                rVec[i] = xVec[i] * yVec[i];
            }
        }

        this.multiplyAddTo = function (rVec, xVec, yVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                rVec[i] += xVec[i] * yVec[i];
            }
        }

        // x-y
        this.subtract = function (rVec, xVec, yVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                rVec[i] = xVec[i] - yVec[i];
            }
        }

        this.add = function (rVec, xVec, yVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                rVec[i] = xVec[i] + yVec[i];
            }
        }

        // converts each element of xVec to +1 or -1 according to its sign.
        this.signOf = function (rVec, xVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                if (xVec[i] < 0.0) {
                    rVec[i] = -1.0;
                } else {
                    rVec[i] = 1.0;
                }
            }
        }

        this.truncate = function (rVec, xVec, t) {
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

        this.sumSq = function (vec) {
            var sum = 0.0;
            for (var i = 0, n = vec.length; i < n; i++) {
                sum += vec[i] * vec[i];
            }
            return sum;
        }

        // Assuming each elememt of is from a Gaussian distribution of zero mean
        // adjust the variance of each element to 1.				
        this.adjust = function (rVec, xVec) {
            var MIN_SQ = 1e-20;
            var adj = 1.0 / Math.sqrt((this.sumSq(xVec) / xVec.length) + MIN_SQ);
            this.scale(rVec, xVec, adj);
        }

        this.copy = function (rVec, xVec) {
            for (var i = 0, n = rVec.length; i < n; i++) {
                rVec[i] = xVec[i];
            }
        }

        this.fillFloat = function (rVec, n) {
            for (var i = 0; i < n; i++) {
                rVec[i] = 0.0;
            }
        }
    }
