(
if (ProxySpace.all[\p] == nil) { 
    var clock = TempoClock(150/60).permanent_(true);
    b = clock.tempo;
    p = ProxySpace(s, \p, clock)
        .fadeTime_(0.02)
        .quant_(1);
    p.push;
};

SynthDef(\saw, {
    var sig, env;

    env = Env.perc(\atk.kr(0.1), \rel.kr(1))
        .kr(Done.freeSelf);
    
    sig = Saw.ar(\freq.kr(440)) * \amp.kr(1); 
    sig = Pan2.ar(sig, \pan.kr(0));

    Out.ar(\out.kr(0), sig);
}).add;


~saw.play;

~saw[0] = Pbind(
    \instrument, \saw,
    \degree, Pseq([
        Pseq([[1, 3, 7]], 1),
        Pseq([[1, 3, 11]], 1),
        Prand([[2, 6, 8]], 1)
    ], inf),
    \octave, Prand([4, 5], inf),
    \atk, Pexprand(0.01, 0.2),
    \rel, Pexprand(0.001, 0.05),
    \amp, Pwhite(-20.dbamp, -10.dbamp),
    \dur, Prand([
        Prand([Rest(4), Rest(2)]),
        Pseq([Rest(1/4), 1/8, 1/8]), 
        Pseq([Rest(1/8), 1/8, Rest(1/4)]),
        Pseq([1/4, 1/4])
    ], inf)
    // \dur, Pseq([ 
    //     Pseq([1/8, 1/4, Rest(1/8), 1]),
    //     Pseq([1/4, Pseq([1/8, Rest(1/8)], 2), Rest(1/4)], 1),
    //     Pseq([Rest(3/8), 1/8, Rest(1/4), 1/8, Rest(1/8)], 1)
    // ], inf),
);
~saw.set(\wet2, 0.5);

~saw[1] = \filterIn -> { |in| 
    var sig;
    
    sig = RLPF.ar(
        in, 
        LFTri.ar(b*3).range(400, 800) * LFNoise2.ar(b/2).range(1, 1.25), 
        Saw.ar(b).range(1, 1.5).reciprocal);

    sig;
};

~saw[3] = \filterIn -> { |in| 
    FreeVerb.ar(
        in, 
        0.05, 
        SinOsc.ar(b/2).range(0.5, 0.75),
        LFNoise1.ar(b*4).range(0.25, 0.5))
}
)

(
~saw[2] = \filterIn -> { |in| 
    CombC.ar(in, b*2, b/6, b)
};
)
