(
s.waitForBoot {
    TempoClock.default = TempoClock(80/60);
    fork {
        var drumBus, drumFx;
        var spawnArp, spawnDrums, spawnPad, spawnSub;
        var play, tdaddr;

        tdaddr = NetAddr("127.0.0.1", 57130);

        play = { |name, args, displayName = nil, samp = 1.0|
            var res;
            s.bind {
                res = Synth(name, args);
                if (displayName == nil) {
                    displayName = name;
                };
                if (samp.coin) {
                    var string = "";

                    args.hash.abs.asString.pairsDo({ |l, r|
                        var asciiCode;
                        asciiCode = (l ++ r).asInteger + 32;
                        asciiCode = asciiCode.min(126);
                        string = string ++ asciiCode.asAscii;
                    });
                    string = displayName ++ " " ++ string;
                    tdaddr.sendMsg(\blobtext, string.asSymbol);
                };
            };
            ^res;
        };

        Import("synthdefs.scd");

        drumBus = Bus.audio(s, 2);
        drumFx = Synth.tail(s, \drumfx, [\in, drumBus]);

        spawnArp = { |basefreq = 120, lowfreq = 1, hifreq = 4|
            var dur, freqs, ratios;

            ratios = [1, 5/4, 3/2, 9/8];
            dur = ratios.size.reciprocal;
            freqs = basefreq * ratios;

            fork {
                loop {
                    freqs.do { |freq|
                        var args;
                        args = [
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
                        ];
                        fork {
                            play.(\pad, args, \arp, 0.25);
                        };
                        dur.wait;
                    };
                }
            };
        };

        spawnDrums = { |slices = 1|
            var buffer, sampleDur, rate, slice, clock, freeSlice;

            clock = TempoClock.default;
            buffer = ~dirt.buffers[\break][20];
            sampleDur = buffer.numFrames / buffer.sampleRate;
            rate = sampleDur / (clock.beatsPerBar / clock.tempo);
            freeSlice = {
                s.bind {
                    slice.free;
                }
            };

            Task {
                loop {
                    slices.do { |item, i|
                        var start, args;
                        start = buffer.numFrames * (item / slices);
                        args = [
                            \buffer, buffer,
                            \rate, rate,
                            \out, drumBus,
                            \start, start,
                            \amp, 0.69
                        ];
                        fork {
                            slice = play.(\playbuf, args, \drums);
                        };
                        (clock.beatsPerBar * (1 / slices)).wait;
                        freeSlice.();
                    };
                }
            }.addDependant(
                fork { |obj, sig|
                    if (sig == \stopped) {
                        freeSlice.();
                    };
                }
            ).play;
        };

        spawnPad = { |basefreq = 180|
            var freqs, dur, ratios;

            ratios = [1, 5/4, 3/2, 9/8];
            freqs = basefreq * ratios;
            dur = 4;

            fork {
                loop {
                    freqs.do { |freq|
                        var args;
                        args = [
                            \freq, freq,
                            \atk, 1/4 * rrand(1, 8),
                            \suslev, rrand(0.5, 1.0),
                            \rel, 2 * rrand(2, 8),
                            \sustime, 4,
                            \amp, rrand(0.1, 0.2)
                        ];
                        fork {
                            play.(\pad, args);
                        };
                    };
                    dur.wait;
                }
            }
        };

        spawnSub = { |basefreq = 120, durs = #[8, 4, 4]|
            var ratios, freqs;

            ratios = [1, 5/4, 3/2];
            freqs = (basefreq * ratios);

            fork {
                loop {
                    freqs.do { |freq, i|
                        var args;
                        args = [
                            \freq, freq,
                            \sustime, 2
                        ];
                        fork {
                            play.(\sub, args);
                        };
                        durs[i].wait;
                    }
                }
            }
        };

        fork {
            var drums, arp, pad, auto, bass;

            tdaddr.sendMsg(\play);

            drums = spawnDrums.();
            arp = spawnArp.();
            16.wait;

            auto = fork {
                var numSteps, dur, waitTime;

                numSteps = 30;
                dur = 16;
                waitTime = dur / numSteps;

                numSteps.do { |step|
                    var hpf, dry;

                    hpf = step.linlin(0, numSteps - 1, 3750, 1500);
                    dry = step.linlin(0, numSteps - 1, 0, 0.5);
                    s.bind {
                        drumFx.set(\dry, dry, \hpf, hpf)
                    };
                    waitTime.wait;
                }
            };
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
            s.bind {
                drumFx.set(\dry, 0.5)
            };
            32.wait;

            [pad, arp].do(_.stop);
            16.wait;

            auto = fork {
                var numSteps, dur, waitTime;

                numSteps = 30;
                dur = 8;
                waitTime = dur / numSteps;

                numSteps.do { |step|
                    var hpf, dry, amp;

                    hpf = step.linlin(0, numSteps - 1, 1500, 3750);
                    dry = step.linlin(0, numSteps - 1, 0.5, 0);
                    amp = step.linlin(0, numSteps - 1, 1, 0.2);

                    s.bind {
                        drumFx.set(\dry, dry, \hpf, hpf, \amp, amp)
                    };
                    waitTime.wait;
                }
            };
            8.wait;

            [drums, auto].stop;
            drumFx.free;
            8.wait;

            bass.stop;

            tdaddr.sendMsg(\stop);
        }
    }
}
)