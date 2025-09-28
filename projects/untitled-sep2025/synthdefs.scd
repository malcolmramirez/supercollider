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

SynthDef.new(\noise, {
    var env, sig, hh;

    env = Env.perc(\atk.kr(0.1), \dec.kr(0.15), curve:-6).kr(Done.freeSelf);
    // Make a square wave
    sig = PinkNoise.ar;

    sig = sig * \amp.kr(-25.dbamp) * env;

    Out.ar(\out.kr(0), Clip.ar(sig!2));
}).add;

SynthDef.new(\syn, {
    var sig, trig, env;

    env = Env.asr(
        \atk.kr(0.5),
        \suslev.kr(1),
        \rel.kr(0.1),
        -4);
    trig = Env.perc(0, \sustime.kr(0.5)).kr;
    //trig = 1;
    env = env.ar(Done.freeSelf, trig);

    sig = Blip.ar(
        \freq.kr(220) * (LFNoise2.ar(\mfreq.kr(10)) * \mamt.kr(0.001) + 1),
        (LFNoise2.ar(50) * 105 + 100)
    )!5;
    sig = LeakDC.ar(sig);
    sig = Mix.ar([
        sig,
        Formant.ar(\freq.kr(220), \freq.kr(220) * 4, \freq.kr(220) * (SinOsc.ar(\bwfmod.kr(10)) + 1) * 5) * 0.1
    ]);
    sig = LPF.ar(sig, \lpff.kr(500));
    sig = sig * env;
    sig = sig * \amp.kr(-1.dbamp);

    Out.ar(\out.kr(0), sig);
}).add;

SynthDef(\playdbuf, {
    var sig = PlayBuf.ar(
        numChannels: 2,
        startPos: \start.kr(0),
        bufnum: \buffer.kr,
        rate: \rate.kr(1));
    sig = sig + PitchShift.ar(sig, pitchRatio: 1.25) * 0.5;
    sig = HPF.ar(sig, \hpf.kr(5000));
    sig = sig * Env.perc(0, \playdur.kr, curve: 100).kr(Done.freeSelf);
    sig = sig * \amp.kr(1);
    Out.ar(\out.kr(0), sig ! 2);
}).add;

SynthDef.new(\pad, {
    var sig, trig, env;

    env = Env.asr(
        \atk.kr(0.1),
        \suslev.kr(1),
        \rel.kr(1),
        -4);
    trig = Env.perc(0, \sustime.kr(0.1)).kr;
    //trig = 1;
    env = env.ar(Done.freeSelf, trig);

    sig = Saw.ar(\freq.kr(110) + LFNoise2.kr(0.1)*1)!3;
    sig = LeakDC.ar(sig);
    sig = LPF.ar(sig, \lpff.kr(400));
    sig = sig * env;
    sig = sig * \amp.kr(-14.dbamp);
    sig = sig ! 2;

    Out.ar(\out.kr(0), sig);
}).add;

SynthDef.new(\padfx, {
    var sig;

    sig = In.ar(\in.kr, 2);
    sig = sig + CombC.ar(sig, 10, \delaytime.kr(0.5), \decaytime.kr(1));
    sig = FreeVerb.ar(sig, 0.5, 0.8, 0.1);

    Out.ar(\out.kr(0), sig);
}).add;

)

(
TempoClock.default = TempoClock(150/60);
{
    var beatDur,
        spawnKick, spawnSyn, spawnStut, spawnNoise, spawnDrums, spawnPad, spawnArp,
        padFx, padBus,
        kick, syn, noise, drums, drums2, pad, arp;

    beatDur = TempoClock.default.beatDur;

    padBus = Bus.audio(s, 2);
    padFx = Synth.tail(s, \padfx, [\in, padBus, \delaytime, beatDur * 1/4, \decaytime, beatDur * 2]);

    spawnNoise = {
        fork {
            inf.do { |i|
                if (0.5.coin) {
                    s.bind {
                        Synth(\noise, [
                            \atk, rrand(0.025, 0.1),
                            \amp, rrand(1.0, 3.0) * -15.dbamp
                        ]);
                    };
                };
                1.5.wait;
            }
        }
    };

    spawnKick = {
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
        }
    };

    spawnDrums = { |playmode=\rand, num=0, ratemul=1, slices=16, hpf=5000, amp=(-1.dbamp)|
        var buffer, sampleDur, rate, slice, clock, freeSlice;

        clock = TempoClock.default;
        buffer = ~dirt.buffers[\break][num];
        sampleDur = buffer.numFrames / buffer.sampleRate;
        rate = sampleDur / (clock.beatsPerBar / clock.tempo) * ratemul;

        fork {
            loop {
                slices.do { |i|
                    var start, playdur, args, slicei;
                    if (playmode == \rand) {
                        slicei = slices.rand;
                    };
                    if (playmode == \seq) {
                        slicei = i;
                    };
                    start = buffer.numFrames * (slicei / slices) * ratemul;
                    start.postln;
                    playdur = rate/slices;
                    args = [
                        \buffer, buffer,
                        \rate, rate,
                        \start, start,
                        \playdur, playdur,
                        \amp, amp,
                        \hpf, hpf
                    ];
                    s.bind {
                        slice = Synth(\playdbuf, args);
                    };
                    (clock.beatsPerBar * (1 / slices)).wait;
                }
            }
        };
    };

    spawnStut = { |freqs|
        fork {
            freqs.do { |freq|
                s.bind {
                    Synth(\syn, [
                        \freq, freq,
                        \atk, beatDur/16,
                        \sustime, 0.01,
                        \rel, rrand(1/8, 1/2) * beatDur,
                        \mfreq, beatDur * 4,
                        \amp, 13.dbamp
                    ]);
                };
                (4..8).reciprocal.choose.wait;
            };
        }
    };

    spawnSyn = { |freqs, chime=true|
        fork {
            inf.do { |i|
                freqs.do { |freq, i|
                    s.bind {
                        Synth(\syn, [
                            \freq, freq,
                            \atk, beatDur/2,
                            \sustime, beatDur,
                            \rel, rrand(10, 15) * beatDur,
                            \mfreq, beatDur * 4,
                            \bwfmod, beatDur * 2,
                            \amp, 3.5.dbamp
                        ]);
                    };
                };
                fork {
                    8.wait;
                    if (chime) {
                        spawnStut.(freqs);
                    };
                };
                16.wait;
            };
        };
    };

    spawnArp = { |freqs|
        fork {
            inf.do { |i|
                freqs.do { |freq, i|
                    s.bind {
                        Synth(\pad, [
                            \freq, freq,
                            \atk, beatDur/16,
                            \sustime, beatDur * 0.5,
                            \rel, beatDur * 0.25,
                            \hd, beatDur * 4,
                            \out, padBus
                        ]);
                    };
                    0.5.wait;
                };
            };
        };
    };

    spawnPad = { |freqs|
        fork {
            inf.do { |i|
                Synth(\pad, [
                    \freq, freqs,
                    \hd, beatDur * 4,
                    \out, padBus
                ]);
                16.wait;
            };
        };
    };

    // Composition here
    drums = spawnDrums.(\rand, 0, 0.5);
    kick = spawnKick.();
    syn = spawnSyn.(440 * [1, 3/2, 10/16, 21/19]);

    16.wait;

    drums.stop;
    noise = spawnNoise.();

    2.wait;
    drums = spawnDrums.(\rand, 0, 0.5);

    14.wait;
    syn.stop;
    syn = spawnSyn.(440 * [1, 3/2, 17/15, 2]);

    16.wait;
    syn.stop;
    syn = spawnSyn.(440 * [1, 3/2, 10/16, 21/19]);

    16.wait;
    syn.stop;
    arp = spawnArp.((440 * [1, 3/2, 10/16, 21/19]) ++ (440 * [1, 3/2, 17/15, 2]));
    // fade

    16.wait;
    syn = spawnSyn.(440 * 3/2 * [1, 3/2, 10/16, 21/19], false);

    32.wait;
    drums.stop;

    drums = spawnDrums.(playmode: \rand, num: 0, ratemul: 0.5, amp: -5.dbamp);
    drums2 = spawnDrums.(playmode: \seq, num: 8, hpf: 500, amp: -1.5.dbamp);

}.fork;
)
