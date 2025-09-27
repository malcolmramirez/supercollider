(

var buf, slicer, slicer2, buf2;

TempoClock.default = TempoClock(150/60);


buf = ~dirt.buffers[\break][27];
buf2 = ~dirt.buffers[\break][11];
slicer = Slicer.new(buffer: buf, rateMultiplier: 1);
slicer2 = Slicer.new(buffer: buf2, rateMultiplier: 1);

slicer.play; slicer2.play;

SynthDef.new(\pad, {
    var env = Env.perc(\atk.kr(0.1), \rel.kr(1)).kr(Done.freeSelf);

    var ampOsc = (SinOsc.kr(0.01) + 1) * \amp.kr(0.2);
	var car = Mix.ar(
		RLPF.ar(
			Pulse.ar(\freq.kr, SinOsc.ar(5) * 0.15 + 0.5),
			Line.ar(\freq.kr * 5, \freq.kr * 50, \rel.kr(1)))
	) * ampOsc * env;
	car = car.tanh;

	Out.ar(\out.kr(0), Clip.ar(car!2));
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

SynthDef.new(\hh, {
    var env, sig, hh;

    env = Env.perc(\atk.kr(0.001), \dec.kr(0.01), curve:-6).kr(Done.freeSelf);
    // Make a square wave
    sig = all {:Pulse.ar(\tone.kr(40) * m), m <- [1, 2.17, 3.31, 4.16, 5.43, 6.79, 8.12] };

    sig = BPF.ar(sig.sum, 10000, 1/10);
    sig = HPF.ar(sig, 5000);
    sig = sig * \amp.kr(1.dbamp) * env;

    Out.ar(\out.kr(0), Clip.ar(sig!2));
}).add;

SynthDef.new(\bass, {
    |out, freq=500, atk=0.1, rel=1, amp=0.2, fAtk=0.001, fRel=0.1, width=0.5, rq|
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var filterEnv = EnvGen.kr(Env.perc(fAtk, fRel, curve:1)) * (freq * 30) + (freq * 10);
    var acid = RLPF.ar(
        Pulse.ar(freq, width:width),
        filterEnv,
        rq
    ) * amp * env;
    Out.ar(out, acid.softclip!2);
}).add;

// pad play
fork {
    var chords = { |scale|
        var ratios = {|ixs| ixs.collect({|n| scale.ratios[n]})};
        65 * 5.sqrt * [
            ratios.([ 0, 2, 6]),
            ratios.([ 0, 1, 5])
            /*
            ratios.([ 0, 2, 5 ]),
            ratios.([ 6, 1, 3 ]) * [1/2, 1, 1],
            ratios.([ 5, 1, 2 ]) * [1/2, 1, 1],
            ratios.([ 3, 5, 2 ]) * [1/2, 1/2, 1]*/
        ]
    };
    var scales = [Scale.lydian, Scale.lydian, Scale.lydian, Scale.lydian];
    //var waits = [[16, 8, 8, 16], [8, 8, 8, 24], [16, 8, 8, 8]];
    var waits = [[16]];
    inf.do { |i|
        var currWaits = waits.foldAt(i);
        chords.(scales.foldAt(i)).do { |chord, j|
            var wait = currWaits.foldAt(j);
            chord.do { |freq|
                s.bind {
                    Synth(\pad, [
                        \freq, freq,
                        \amp, exprand(0.2, 0.275),
                        \atk, exprand(1, 1.5),
                        \rel, wait - rrand(wait * 1/16, wait * 2/4)
                    ])
                };
            };
            wait.wait;
        }
    }
};

fork {
    inf.do { |i|
        s.bind {
            Synth(\kick);
        };
        if ((i % 16 == 0) && (i != 0)) {
            0.5.wait;
            s.bind {
                Synth(\kick);
            };
            0.5.wait;
        } {
            1.wait;
        }
    }
};

fork {
    var chords = { |scale|
        var ratios = {|ixs| ixs.collect({|n| if (n == \) {n} {scale.ratios[n]}})};
        65 * (3/4) * 5.sqrt * [
            ratios.([ 0, \, \, \]),
            ratios.([ 0, \, 5, 1]),/*
            ratios.([ 0, 2, 6, 4]),
            ratios.([ 0, 1, 5, 3]),*/
            /*
            ratios.([ 0, 2, 5 ]),
            ratios.([ 6, 1, 3 ]) * [1/2, 1, 1],
            ratios.([ 5, 1, 2 ]) * [1/2, 1, 1],
            ratios.([ 3, 5, 2 ]) * [1/2, 1/2, 1]*/
        ]
    };
    var scales = [Scale.lydian, Scale.lydian, Scale.lydian, Scale.lydian];
    inf.do { |i|
        chords.(scales.foldAt(i)).do { |chord, j|
            chord.do { |freq|
                if (freq != \) {
                    s.bind {
                        Synth(\bass, [
                            \freq, freq,
                            \atk, 0.001,
                            \rel, 0.1,
                            \fRel, 0.1,
                            \width, 0.5,
                            \rq, 1/15,
                            \amp, -8.dbamp
                        ])
                    };
                };
                (1/4).wait;
            };
        }
    }
};

)