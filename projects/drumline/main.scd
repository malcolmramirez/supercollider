(
var tempo = 150/60;
TempoClock.default = TempoClock(tempo);
s.waitForBoot {
    var sem = Semaphore(3);
    var hipbus = Bus.audio(s, 2);

    fork {
        var hip, hipauto, mainbreak, kick, pads, hibreaks = [\,\];

        Import("synthdefs.scd");

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
}
)