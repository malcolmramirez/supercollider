(
~tempo = 130/60;
~bar2sec = ~tempo * 4;
TempoClock.default.tempo = ~tempo;
)

(
Ndef(\pad, {
    var sig, env, freqs, lfos; 

    freqs = \freq.kr([0, 0, 0, 0]);

    env = Env
        .perc(\atk.kr(0.01), \rel.kr(0.1))
        .ar(gate: \t_trig.tr(0));

    sig = Saw.ar(freqs);
    sig = Mix.ar(sig);

    sig = RLPF.ar(
        sig, 
        SinOsc.ar(~bar2sec/4).linlin(-1, 1, 110, 440), 
        Env.perc(0, 0.5, curve: -2)
           .ar(gate: \t_trig.tr(0))
           .linlin(0, 1, 0.33, \q.kr(1).reciprocal));

    sig = sig * env * \vol.kr(1);

    sig ! 2;
});
)

(
Ndef(\dubfx, {
    var sig;

    sig = \in.ar([0,0]);
    sig = FreeVerb.ar(sig, \mix.kr(0.5), \room.kr(0.75), \damp.kr(0.5));
    sig = CombC.ar(sig, ~bar2sec, ~bar2sec/(3*4), ~bar2sec*2);
    sig = LPF.ar(sig, 660);

    sig;
});

Ndef(\dubfx) <<>.in Ndef(\pad);
)

(
Ndef(\kick, {
    var sig, env, trig;

    trig = \t_trig.tr(0);

    sig = SinOsc.ar(
        Env([70, 40], [0.001], \exp, curve: -4).ar(gate: trig)
    );

    env = Env.perc(\atk.kr(0.025), \rel.kr(0.25)).ar(gate: trig);
    sig = sig * env;
    sig = LPF.ar(sig, 150);
    sig = sig.tanh * \vol.kr(1);
    sig;
});

Ndef(\noise, {
    var sig, env, trig;

    trig = \t_trig.tr(0);

    // sig = Saw.ar(110 * [LFNoise2.ar(55).linlin(-1, 1, 1.0001, 1.01)]!4) * (1/4);
    
    sig = WhiteNoise.ar;
    sig = BPF.ar(sig, 440);

    // sig = RLPF.ar(sig, 440, Env([1, SinOsc.ar(bar2sec*8).linlin(-1, 1, 0.5, 1)], [0.1], curve: -4).ar(gate: trig));
    sig = Mix.ar(sig);
    
    env = Env.perc(\atk.kr(0.01), \rel.kr(0.1)).ar(gate: trig);
    sig = sig * env;
    sig = sig * \vol.kr(1);
    
    Pan2.ar(sig, pos:TRand.kr(-1, 1, trig));
});
)


Ndef(\dubfx).play;

Ndef(\kick).play;

Ndef(\noise).play;


(
Tdef(\noise, {
    loop {
        var waitTime = [1/2].choose;
        waitTime.wait;
        Ndef(\noise).set(
            \atk, rrand(0.001, 0.01),
            \rel, rrand(0.15, 0.25),
            \vol, rrand(0.75, 1) * -10.dbamp, 
            \t_trig, 1);
        waitTime.wait;
    }
}).play;
)

(
Tdef(\kick, {
    loop {
        Ndef(\kick).set(
            \vol, 1,
            \atk, 0.001,
            \t_trig, 1);
        (1/2).wait;
    }
}).play;

Tdef(\prog, {
    loop {
        [
            //"as3_maj7",
            "d3_maj7"
//            "as3_min7",
//            "c4_maj7",
//            "as3_maj7",
//            "bf3_min7",
        ]
        .collect({|c| Note.toFreq(c)})
        .do { |freqs|
            Ndef(\pad).set(
                \freq, freqs, 
                \atk, 0.1,
                \rel, 0.25,
                \q, 0.1,
                \vol, 11.dbamp,
                \t_trig, 1);
            4.wait;
        }
    }
}).play
)
