(
TempoClock.default = TempoClock(150/60);
b = ~dirt.buffers[\soundthread][0];


fork {
    Slicer(~dirt.buffers[\soundthread][0], 1/8, amp: 10).play;
    Slicer(~dirt.buffers[\break][13], 0.5, amp: 0.5, numSlices: 64).play;
}
)

(
SynthDef.new(\kick, {
    var sig, modsig, env, freqEnv;

    env = Env.perc(
        \atk.kr(0.001), \rel.kr(0.25), curve: -2).ar(gate: \t_gate.kr(0));

    modsig = Saw.ar(\mod.kr(50)) / 4 + 1;

    sig = SinOsc.ar(\freq.kr(100) * (env * \punch.kr(1.2)) * modsig);

    sig = sig * env * \amp.kr(4.dbamp);
    sig = sig!2;

    Out.ar(\out.kr(0), sig);
}).add;


SynthDef.new(\hh, {
	|out, tone=80, atk=0.005, dec=0.05, amp=1|
	var env = EnvGen.kr(
		Env.new([0, 1, 0], [atk, dec], curve:[-6, -6]),
		gate: \t_gate.kr(0));

	// Make a square wave
	var pulses = all {:Pulse.ar(tone * m), m <- [1, 2.17, 3.31, 4.16, 5.43, 6.79, 8.12] };
	var hh2 = BPF.ar(pulses.sum, 10000, 1/10);
	hh2 = HPF.ar(hh2, 7500);

	hh2 = hh2 * env;
	Out.ar(out, Clip.ar(hh2!2) * amp);
}).add;

SynthDef.new(\metal, {
    |out, freq=500, mRatio=1, cRatio=1, index=1, atk=0.0025, rel=0.25, amp=1, room=0.5, damp=0.5|
    var env = EnvGen.kr(Env.perc(atk, rel), gate: \t_gate.kr(0));
    var mod = SinOsc.ar(freq, mul:freq * mRatio * index);
    var car = RLPF.ar(
        Pulse.ar(freq * cRatio + mod, mul:amp),
        XLine.kr(freq * 10, freq * 30, rel))!2;
    var reverbed = FreeVerb2.ar(
        car[0], // Left channel
        car[1], // Right Channel
        0.75, room, damp, amp) * env;
    Out.ar(out, reverbed.tanh) ;
}).add;

SynthDef.new(\bass, {
    |out, freq=500, atk=0.1, rel=1, amp=0.2, fAtk=0.0001, fRel=0.1, width=0.5, rq=0.1|
    var env = EnvGen.kr(Env.perc(atk, rel), gate: \t_gate.kr(0));
    var filterEnv = EnvGen.kr(Env.perc(fAtk, fRel, curve:1), gate: \t_gate.kr(0)) * (freq * 30) + (freq * 10);
    var acid = RLPF.ar(
        Pulse.ar(freq, width:width),
        filterEnv,
        rq
    ) * amp * env;
    Out.ar(out, acid!2);
}).add;
)

FreqScope.new(400, 200, 0, server: s);

(
TempoClock.default = TempoClock(150/60);

fork {
    var kick;
    var hh;
    var metal;
    var bass;

    kick = Cycle[
        \def -> \kick,
        \t_gate -> Euc(5, 16),
        \atk -> Euc(5, 16, on: Alt(0.01, 0.025, 0.001, 0.01))
    ]
    .run;

    hh = Cycle[
        \def -> \hh,
        \t_gate -> Euc(11, 16)
    ]
    .run;

    metal = Cycle[
        \def -> \metal,
        \t_gate -> Euc(2, 16, 4)
    ]
    .run;

    bass = Cycle[
        \def -> \bass,
        \t_gate -> Alt(Euc(7, 16), Euc(11, 16, 1)),
        \freq -> Euc(7, 16, on: {55})
    ]
    .run;

    16.wait;

    bass << (
        \freq -> Euc(7, 16, on: Alt(35, 55, 55, 55))
    );

    metal << (
        \t_gate -> Alt(Euc(2, 16, 6), Euc(3, 16, 3))
    );

    16.wait;

    kick << (
        \t_gate -> Euc(3, 8)
    );

    hh << (
        \t_gate -> Euc(5, 16, 4)
    );
};
)