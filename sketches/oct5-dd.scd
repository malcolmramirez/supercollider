(

SynthDef.new(\fmgrain, {
    var sig, env;

    sig = FMGrain.ar(
        trigger: Impulse.ar(SinOsc.ar(LFNoise2.ar(5).range(1, 100)).range(1, 100)),
        dur: 0.15,
        carfreq: \freq.kr(440),
        modfreq: \modfreq.kr(120),
        index: Saw.ar(10).range(1, 4));

    env = Env.adsr(\atk.kr(1), \dec.kr(1), \suslev.kr(1), \rel.kr(1), curve: -4);
    env = env.ar(gate: Env([1, 1, 0], [\sustime.kr(inf), 0]).kr, doneAction: Done.freeSelf);
    sig = sig * env * \amp.kr(-20.dbamp);

    Out.ar(\out.kr(0), sig!2);
}).add;

SynthDef.new(\grain, {
    var sig, env;

    sig = GrainBuf.ar(
        trigger: Dust.ar(SinOsc.ar(10).range(1, 100)),
        dur: SinOsc.ar(SinOsc.ar(10).range(0.5, 10)).range(0.001, 0.5),
        sndbuf: \buffer.kr,
        pos: Saw.ar(SinOsc.ar(0.5).range(0.5, 1)).range(0, 1),
        interp: 2);

    env = Env.adsr(\atk.kr(1), \dec.kr(1), \suslev.kr(1), \rel.kr(1), curve: -4);
    env = env.ar(gate: Env([1, 1, 0], [\sustime.kr(inf), 0]).kr, doneAction: Done.freeSelf);
    sig = sig * env * \amp.kr(1);

    Out.ar(\out.kr(0), sig!2);
}).add;


SynthDef.new(\kick, {
    var sig, modsig, env, freqEnv;

    env = Env.perc(\atk.kr(0.001), \rel.kr(0.25), curve: -2).ar(Done.freeSelf);
    modsig = Saw.ar(\mod.kr(50)) / 4 + 1;

    sig = SinOsc.ar(\freq.kr(100) * (env * \punch.kr(1.2)) * modsig);

    sig = sig * env * \amp.kr(4.dbamp);
    sig = sig!2;

    Out.ar(\out.kr(0), sig);
}).add;
)



(
~tempo = 120/60;
TempoClock.default = TempoClock(~tempo);

fork {

    /*fork {
        Slicer.new(
            ~dirt.buffers[\clubcode1][14],
            0.5,
            transitionFunction:{|x| (
                x + sin(x / exprand(2, x.max(2))).linlin(-1, 1, 0, exprand(4, x.max(4))) + 1) % 32
            },
            numSlices: 32,
            amp: 1,
            out: 0).play;
    };
    //32.wait;
    */
    s.bind {
        Synth(\grain, [\buffer, 38, \amp, 2.dbamp])
    };

    //32.wait;

    fork {
        loop {
            [
                [\, \, \, 1, \, \, \, \],
                [\, 1, \, \, 1, \, 0.5, \],
            ].do { |seq|
                seq.do { |it|
                    if (it != \) {
                        Synth(\kick, [\freq, 55, \rel, 1, \amp, it]);
                    };
                    (8/seq.size).wait;
                }
            }
        }
    };

    s.bind {
        Synth(\fmgrain, [\freq, 440, \sustime, 32]);
    };

    //32.wait;

}

)