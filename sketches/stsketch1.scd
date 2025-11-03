(
SynthDef.new(\pad, {
    var env = Env.perc(\atk.kr(0.1), \rel.kr(1), curve:-10).ar(Done.freeSelf);

    var ampOsc = (SinOsc.kr(0.01) + 1) * \amp.kr(1);
	var car = Mix.ar(
		RLPF.ar(
            Pulse.ar(\freq.kr(220), SinOsc.ar(5) * 0.15 + 0.5), \lpf.kr(500))
	) * ampOsc * env;

    car = HPF.ar(car, \hpf.kr(1000));

	car = car.tanh;

	Out.ar(\out.kr(0), Clip.ar(car!2));
}).play;

SynthDef.new(\kick, {
    var sig, modsig, env, freqEnv;

    env = Env.perc(
        \atk.kr(0.001), \rel.kr(0.25), curve: -2).ar(Done.freeSelf);

    modsig = Saw.ar(\mod.kr(50)) / 4 + 1;

    sig = SinOsc.ar(\freq.kr(100) * (env * \punch.kr(1.2)) * modsig);

    sig = sig * env * \amp.kr(4.dbamp);
    sig = sig!2;

    Out.ar(\out.kr(0), sig);
}).play;


SynthDef.new(\hh, {
	|out, tone=80, atk=0.005, dec=0.05, amp=1|
	var env = EnvGen.kr(
		Env.new([0, 1, 0], [atk, dec], curve:[-6, -6]),
		doneAction: 2);

	// Make a square wave
	var pulses = all {:Pulse.ar(tone * m), m <- [1, 2.17, 3.31, 4.16, 5.43, 6.79, 8.12] };
	var hh2 = BPF.ar(pulses.sum, 10000, 1/10);
	hh2 = HPF.ar(hh2, 7500);

	hh2 = hh2 * env;
	Out.ar(out, Clip.ar(hh2!2) * amp);
}).add;

SynthDef.new(\metal, {
    |out, freq=500, mRatio=1, cRatio=1, index=1, atk=0.0025, rel=0.25, amp=1, room=0.5, damp=0.5|
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction: 2);
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
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction: 2);
    var filterEnv = EnvGen.kr(Env.perc(fAtk, fRel, curve:1)) * (freq * 30) + (freq * 10);
    var acid = RLPF.ar(
        Pulse.ar(freq, width:width),
        filterEnv,
        rq
    ) * amp * env;
    Out.ar(out, acid!2);
}).add;
)

)

(
~seq = TimeSeq([1, [1, 2]]);
)

(
~seq.next;

)

(
"".class
)

(
TempoClock.default = TempoClock(150/60);

fork {
    var kick;
    var hh;
    var metal;
    var bass;
    var pad;

    kick = Cycle[
        \def -> \kick,
        \spawn -> Euc(5, 16),
        \speed -> 1,
        \atk -> Alt(0.001, [Alt(0.025, 0.0001), 0.025])
    ].run;

    pad = Cycle[
        \def -> \pad,
        \spawn -> 1,
        \freq -> Alt("d3_min", "d3_11s"),
        \rel -> 1,
        \atk -> 0.15,
    ].run;

    hh = Cycle[
        \def -> \hh,
        \spawn -> Euc({7 + 6.rand}, 16)
    ].run;

    metal = Cycle[
         \def -> \metal,
         \spawn -> Euc(2, 16, 4)
    ].run;

    bass = Cycle[
        \def -> \bass,
        \speed -> 2,
        \spawn -> Alt(
            [1, 1, 1, 1],
            [1, \, \, 1],
            [1, \, [\, 1, \, \], [1, 1]]
        ),
        \rel -> 0.0001,
        \freq -> "d1"
    ].run;

    16.wait;

    pad = Cycle[
        \def -> \pad,
        \spawn -> 1,
        \speed -> 0.25,
        \freq -> Alt("d4_min", "d4_11s", "d4_7s10"),
        \amp -> -10.dbamp,
        \rel -> 12,
        \atk -> 4,
    ].run;
}


)

Platform.userExtensionDir

    /*hh = Cycle[
        \def -> \hh,
        \spawn -> Euc(11, 16)
    ]
    .run;

    metal = Cycle[
         \def -> \metal,
         \spawn -> Euc(2, 16, 4)
    ].run;*/
    //
    /*// */
    //
    /*bass = Cycle[
        \def -> \bass,
        \spawn -> Alt(Euc(7, 16), Euc(11, 16, 1)),
        \freq -> 55
    ].run;
    //
    // 16.wait;
    //
    // bass << (
    //     \freq -> Euc(6, 16, 2, on: Alt(35, 35, 35, 55))
    // );
    //
    // metal << (
    //     \t_gate -> Alt(Euc(2, 16, 6), Euc(3, 16, 3))
    // );
    //
    // 16.wait;
    //
    // kick << (
    //     \t_gate -> Euc(3, 8)
    // );
    //
    // hh << (
    //     \t_gate -> Euc(5, 16, 4)
    // );
    //
    // 16.wait;
    //
    // bass.stop;
    //
    // kick << (
    //     \t_gate -> Euc(5, 16)
    // );
    //
    // hh << (
    //     \t_gate -> Euc(11, 16)
    // );
    //
    // 16.wait;
    //
    // bass << (
    //     \freq -> Euc(2, 16, 3, on: Alt(35, 35, 35, 55))
    // );
    //
    // 16.wait;
    //
    // [kick, bass, hh, metal].collect{_.stop}
};
)