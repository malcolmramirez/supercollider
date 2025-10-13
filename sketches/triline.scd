

(

SynthDef.new(\kick, {
    var sig, modsig, env, freqEnv;

    env = Env.perc(\atk.kr(0.001), \rel.kr(0.25), curve: -2).ar(Done.freeSelf);
    modsig = Saw.ar(\mod.kr(50)) / 4 + 1;

    sig = SinOsc.ar(\freq.kr(100) * (env * \punch.kr(1.2)) * modsig);

    sig = sig * env * \amp.kr(4.dbamp);
    sig = sig!2;

    Out.ar(\out.kr(0), sig);
}).add;


// Synthdefs
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

SynthDef.new(\hip, {
    var sig;
    sig = In.ar(\in.kr, 2);
    sig = HPF.ar(sig, \hpf.kr(2500));
    Out.ar(\out.kr(0), sig);
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

SynthDef.new(\bass, {
    |out, freq=500, atk=0.1, rel=1, amp=0.2, fAtk=0.001, fRel=0.1, width=0.5, rq|
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var filterEnv = EnvGen.kr(Env.perc(fAtk, fRel, curve:1)) * (freq * 30) + (freq * 10);
    var acid = RLPF.ar(
        Pulse.ar(freq, width:width),
        filterEnv,
        rq
    ) * amp * env;
    Out.ar(out, acid!2);
}).add;


)

(
var sem = Semaphore(3);

var hipbus = Bus.audio(s, 2);

var tempo = 150/60;
TempoClock.default = TempoClock(tempo);

fork {
    var hip, hipauto, hibreak, mainbreak, kick, kicksig, pads, hibreaks = [\,\];

    s.bind {
        hip = Synth.tail(s, \hip, [\in, hipbus, \hpf, 2000]);
    };

    hipauto = fork {
        loop {
            Automator.new(hip).run(16, [
                [
                    \param, \hpf,
                    \func, {|x| cos(x) + 1},
                    \over, [0, (2..4).choose*pi],
                    \range, [100, 2500]
                ]
            ]);
            16.wait;
        }
    };

    pads = ([[220], [220 * 7/11], [220 * 3/2], [440, 220 * 15/11]] / 2).collect { |base|
        fork {
            loop {
                var curr = 1;
                var state = Dictionary[
                    1 -> [17/11],
                    17/11 -> [7/11, 6/11],
                    7/11 -> [1],
                    6/11 -> [3/11, 1],
                    3/11 -> [17/11]
                ];
                var freq = base.choose * curr;
                var relInSec = (tempo.reciprocal * 16);
                var waitTime;
                sem.wait;
                ("playing" + freq).postln;
                s.bind {
                    Synth(\pad, [
                        \freq, freq,
                        \amp, exprand(-7.0, -3.0).dbamp,
                        \atk, exprand(relInSec/8, relInSec/4),
                        \rel, relInSec
                    ]);
                };
                waitTime = ((4..8) * 4).choose;

                waitTime.wait;
                sem.signal;

                curr = state[curr].choose;
            }
        }
    };

    fork {
        hibreaks[0] = Slicer.new(
            ~dirt.buffers[\break][8],
            1,
            transitionFunction:{|x| (x-exprand(1, 2) + exprand(1, 4)) % 64},
            numSlices: 32,
            amp: 2.dbamp,
            out: hipbus).play;
        4.wait;
        hibreaks[1] = Slicer.new(
            ~dirt.buffers[\break][8],
            0.5,
            transitionFunction:{|x| (x-exprand(1, 2) + exprand(1, 4)) % 64},
            numSlices: 32,
            amp: 2.dbamp,
            out: hipbus).play;
    };

    mainbreak = Slicer.new(
        ~dirt.buffers[\break][23],
        0.5,
        numSlices: 64,
        amp: 1,
        out: hipbus).play;
    8.wait;

    kick = fork {
        inf.do { |i|
            s.bind {
                Synth(\kick, [\amp, 5.dbamp]);
            };
            if ((i % 16 == 0) && (i != 0)) {
                0.5.wait;
                s.bind {
                    Synth(\kick, [\amp, 5.dbamp]);
                };
                0.5.wait;
            } {
                1.wait;
            };
        }
    };

    64.wait;

    hibreaks.do{|bk| bk.stop};

    16.wait;

    mainbreak.stop;

    8.wait;

    kick.stop;

    pads.do{ |pad| pad.stop};
    hipauto.stop;
}
)