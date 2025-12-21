(
SynthDef(\simpleSaw, {
    var sig, env, freq;

    env = Env.perc(\atk.kr(0.01), \rel.kr(0.05)).kr(Done.freeSelf);
    sig = Saw.ar(\freq.kr);
    sig = sig * env;

    Out.ar(\i_out.kr(0), sig!2);
}).add;

SynthDef(\lpf, { 
    var sig;
    sig = RLPF.ar(\in.ar(0!2), \lpf.kr(440), \lpq.kr(1).reciprocal);
    Out.ar(\i_out.kr(0), sig);
}).add;

SynthDef(\delay, { 
    var sig;
    sig = CombC.ar(
        \in.ar(0!2), 
        \maxdelaytime.kr(0.2), 
        \delaytime.kr(0.2),
        \decaytime.kr(1));
    Out.ar(\i_out.kr(0), sig);
}).add;

Def(\tester)
    .in(\simpleSaw)
    .on("1*16")
    .freq("c4 e4 g4 b4 c4 e4 g4 b4 c4 e4 g4 b4 c4 e4 g4 b4")
    .atk { SinOsc.kr(0.5).linlin(-1, 1, 0.1, 0.25) }
    .snake(\lpf)
    .lpf { SinOsc.kr(0.5).linlin(-1, 1, 200, 2400) }
    .lpq { Saw.kr(0.1).linlin(-1, 1, 0.1, 3) }
    .snake(\delay)
    .decaytime { 1 }
    .delaytime { 0.2 }
    // .rel({SinOsc.ar(0.5).linlin(-1, 1, 0.5, 1)}) 
)

