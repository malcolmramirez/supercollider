(
fork {
    var i = Import("synthdefs.scd");
    var clock = TempoClock(80/60);

    var drumBus = Bus.audio(s, 2);
    var drumFx = Synth.tail(s, \drumfx, [\in, drumBus]);

    var spawnArp = {
        arg basefreq = 120,
            ratios = [1, 5/4, 3/2, 9/8],
            lowfreq = 1,
            hifreq = 4;
        var dur = ratios.size.reciprocal,
            freqs = basefreq * ratios;
        Routine {
            loop {
                freqs.do {
                    arg freq;
                    Routine {
                        s.bind {
                            Synth(\pad, [
                                \freq, freq * rrand(lowfreq, hifreq),
                                \atk, 1/16 * ([0.5, 1, 2].choose),
                                \suslev, 1,
                                \rel, 1/4 * rrand(4, 8),
                                \sustime, 1/16,
                                \lpff, rrand(100, 500),
                                \lfo, rrand(2, 32),
                                \amp, rrand(0.15, 0.3),
                                \formantAmt, rrand(0.05, 0.15),
                                \pitchwob, rrand(0.001, 0.035)
                            ]);
                        };
                    }.play(clock: clock);
                    dur.wait;
                };
            }
        }.play(clock: clock);
    };


    var spawnDrums = {
        arg pitchShiftDry, slices = 1;

        var buffer = ~dirt.buffers[\break][20],
            sampleDur = buffer.numFrames / buffer.sampleRate,
            rate = sampleDur / (clock.beatsPerBar / clock.tempo),
            slice;

        var task = Task {
            loop {
                slices.do {
                    arg item, i;
                    var start;
                    start = buffer.numFrames * (item / slices);
                    s.bind {
                        slice = Synth(\playbuf, [
                            \buffer, buffer,
                            \rate, rate,
                            \out, drumBus,
                            \start, start,
                            \amp, 0.69
                        ]);
                    };
                    (clock.beatsPerBar * (1 / slices)).wait;
                    s.bind {
                        slice.free;
                    }
                };
            }
        };
        task.addDependant(Routine {
            arg obj, sig;
            if (sig == \stopped) {
                s.bind { slice.free };
            };
        });
        task.play(clock);
    };

    var spawnPad = {
        arg basefreq = 180,
            ratios = [1, 5/4, 3/2, 9/8];
        var freqs = basefreq * ratios,
            dur = 4;
        Routine {
            loop {
                freqs.do {
                    arg freq;
                    Routine {
                        s.bind {
                            Synth(\pad, [
                                \freq, freq,
                                \atk, 1/4 * rrand(1, 8),
                                \suslev, rrand(0.5, 1.0),
                                \rel, 2 * rrand(2, 8),
                                \sustime, 4,
                                \amp, rrand(0.1, 0.2)
                            ]);
                        };
                    }.play(clock: clock);
                };
                dur.wait;
            }
        }.play(clock: clock);
    };

    var spawnSub = {
        arg basefreq = 120,
            ratios = [1, 5/4, 3/2],
            durs = [8, 4, 4];
        var freqs = (basefreq * ratios);
        Routine {
            loop {
                freqs.do {
                    arg freq, i;
                    Routine {
                        s.bind {
                            Synth(\sub, [
                                \freq, freq,
                                \sustime, 2
                            ]);
                        };
                    }.play(clock: clock);
                    durs[i].wait;
                }
            }
        }.play(clock: clock);
    };

    Routine {
        var drums, arp, pad, auto, bass;

        drums = spawnDrums.();

        arp = spawnArp.();
        16.wait;

        auto = Routine {
            var numSteps = 30,
                dur = 16,
                waitTime = dur / numSteps;
            numSteps.do {
                arg step;
                var hpf = step.linlin(0, numSteps - 1, 3750, 1500),
                    dry = step.linlin(0, numSteps - 1, 0, 0.5);
                s.bind { drumFx.set(\dry, dry, \hpf, hpf) };
                waitTime.wait;
            }
        }.play(clock: clock);
        16.wait;

        [drums, arp, auto].do(_.stop);
        arp = spawnArp.(basefreq: 360, lowfreq: 1, hifreq: 2);
        pad = spawnPad.();
        2.wait;

        s.bind { drumFx.set(\dry, 0.5) };
        drums = spawnDrums.();
        16.wait;

        [pad, arp].do(_.stop);
        pad = spawnPad.(basefreq: 360 * 1.5);
        arp = spawnArp.(basefreq: 180, lowfreq: 1, hifreq: 2);
        16.wait;

        [pad, arp].do(_.stop);
        arp = spawnArp.(basefreq: 360, lowfreq: 1, hifreq: 2);
        pad = spawnPad.();
        16.wait;

        [pad, arp].do(_.stop);
        s.bind { drumFx.set(\dry, 0) };
        pad = spawnPad.(basefreq: 360 * 1.5);
        bass = spawnSub.(basefreq: 45);
        8.wait;

        pad.stop;
        arp = [
            spawnArp.(basefreq: 135, hifreq: 2),
            spawnArp.(basefreq: 135, lowfreq: 3, hifreq: 4)
        ];
        16.wait;

        pad = spawnPad.(basefreq: 360 * 1.5);
        16.wait;

        arp[1].stop;
        arp = arp[0];
        // bring back kick drum
        s.bind { drumFx.set(\dry, 0.5) };
        32.wait;

        [pad, arp].do(_.stop);
        16.wait;arp = spawnArp.();
        16.wait;

        auto = Routine {
            var numSteps = 30,
                dur = 16,
                waitTime = dur / numSteps;
            numSteps.do {
                arg step;
                var hpf = step.linlin(0, numSteps - 1, 3750, 1500),
                    dry = step.linlin(0, numSteps - 1, 0, 0.5);
                s.bind { drumFx.set(\dry, dry, \hpf, hpf) };
                waitTime.wait;
            }
        }.play(clock: clock);
        16.wait;

        [drums, arp, auto].do(_.stop);
        arp = spawnArp.(basefreq: 360, lowfreq: 1, hifreq: 2);
        pad = spawnPad.();
        2.wait;

        s.bind { drumFx.set(\dry, 0.5) };
        drums = spawnDrums.();
        16.wait;

        [pad, arp].do(_.stop);
        pad = spawnPad.(basefreq: 360 * 1.5);
        arp = spawnArp.(basefreq: 180, lowfreq: 1, hifreq: 2);
        16.wait;

        [pad, arp].do(_.stop);
        arp = spawnArp.(basefreq: 360, lowfreq: 1, hifreq: 2);
        pad = spawnPad.();
        16.wait;

        [pad, arp].do(_.stop);
        s.bind { drumFx.set(\dry, 0) };
        pad = spawnPad.(basefreq: 360 * 1.5);
        bass = spawnSub.(basefreq: 45);
        8.wait;

        pad.stop;
        arp = [
            spawnArp.(basefreq: 135, hifreq: 2),
            spawnArp.(basefreq: 135, lowfreq: 3, hifreq: 4)
        ];
        16.wait;

        pad = spawnPad.(basefreq: 360 * 1.5);
        16.wait;

        arp[1].stop;
        arp = arp[0];
        // bring back kick drum
        s.bind { drumFx.set(\dry, 0.5) };
        32.wait;

        [pad, arp].do(_.stop);
        16.wait;

        auto = Routine {
            var numSteps = 30,
                dur = 8,
                waitTime = dur / numSteps;
            numSteps.do {
                arg step;
                var hpf = step.linlin(0, numSteps - 1, 1500, 3750),
                    dry = step.linlin(0, numSteps - 1, 0.5, 0),
                    amp = step.linlin(0, numSteps - 1, 1, 0);
                s.bind { drumFx.set(\dry, dry, \hpf, hpf, \amp, amp) };
                waitTime.wait;
            }
        }.play(clock: clock);
        8.wait;

        [drums, auto].stop;
        drumFx.free;
        8.wait;

        bass.stop;

    }.play(clock: clock);
}
)