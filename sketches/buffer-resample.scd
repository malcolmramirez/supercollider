(
~buffer = ~dirt.buffers[\break][20];
)

(
var fx = Bus.audio(s, 2);
var clock = TempoClock.new(80/60);
var sampleDur = ~buffer.numFrames / ~buffer.sampleRate;
var rate = sampleDur / (clock.beatsPerBar / clock.tempo);

Synth.tail(s, \drumfx, [\in, fx, \dry, 0.6, \rate, rate]);

Routine({
    loop {
        arg li;
        var slices = 8;
        slices.do({
            arg item, i;
            var start = ~buffer.numFrames * (item / slices);
            var slice = Synth(\playbuf, [
                \buffer, ~buffer,
                \rate, rate,
                \out, fx,
                \start, start,
                \freq, 360 * 3/2,
                //\dry, 1 - (i/slices),
                \dry, 1,
                \amp, 0.7
            ]);
            (clock.beatsPerBar * (1 / slices)).wait;
            slice.free;
        });
    }
}).play(clock: clock);

Routine({
    var dur = 1/4;
    loop {
        var freqs = 360 / 3 * [1, 5/4, 3/2, 9/8];
        freqs.do({
            arg freq;
            Routine({
                Synth(\pad, [
                    \freq, freq * rrand(1, 4),
                    \atk, 1/16 * ([0.5, 1, 2].choose),
                    \suslev, 1,
                    \rel, 1/4 * rrand(4, 8),
                    \sustime, 1/16,
                    \lpff, rrand(100, 500),
                    \lfo, rrand(2, 32),
                    \amp, rrand(0.2, 0.35),
                    \formantAmt, rrand(0.05, 0.15),
                    \pitchwob, rrand(0.001, 0.035)
                ]);
            }).play(clock: clock);
            dur.wait;
        });
    }
}).play(clock: clock);

/*Routine({
    var dur = 4;
    loop {
        var freqs = 180 * [1, 5/4, 3/2, 9/8];
        freqs.do({
            arg freq;
            Routine({
                Synth(\pad, [
                    \freq, freq,
                    \atk, 1/4 * rrand(1, 8),
                    \suslev, rrand(0.5, 1.0),
                    \rel, 2 * rrand(2, 8),
                    \sustime, 4,
                    \amp, rrand(0.15, 0.25)
                ]);
            }).play(clock: clock);
        });
        dur.wait;
    }
}).play(clock: clock);*/

)

(
SynthDef(\pad, {
    var sig, env, trig;

    env = Env.asr(
        \atk.kr(0.5),
        \suslev.kr(1),
        \rel.kr(0.1),
        \sine);
    trig = Env.perc(0, \sustime.kr(2)).kr;
    //trig = 1;
    env = env.ar(Done.freeSelf, trig);

    sig = Saw.ar(\freq.kr(440) * ({ LFNoise2.ar(\lfo.kr(8), mul: \pitchwob.kr(0.0025), add: 1) } ! 4));
    sig = LPF.ar(sig, \lpff.kr(500) * (1 + env));
    sig = Mix.ar([
        sig,
        Formant.ar(
            \freq.kr(440) / 2,
            ((BrownNoise.kr(add: 1) / 4) + SinOsc.kr(1, add: 1)) * \freq.kr(440),
            LFNoise2.kr(0.1, mul: 1200).abs,
            mul: \formantAmt.kr(0.05))
    ]);
    sig = LeakDC.ar(sig);
    sig = PitchShift.ar(
        sig,
        0.02,
        (1 + (LFNoise2.kr(1, mul: 0.2).abs / 6)),
        0.001,
        0);
    sig = env * sig * \amp.kr(0.2);

    Out.ar(\out.kr(0), sig);
}).add;

SynthDef(\playbuf, {
    var sig = PlayBuf.ar(
        numChannels: 2,
        startPos: \start.kr(0),
        bufnum: \buffer.kr,
        rate: \rate.kr(1)) * \amp.kr(1);
    sig = Mix.ar([
        sig * \dry.kr(0.5),
        FreqShift.ar(sig, \freq.kr(440)) * (1 - \dry.kr(0.5))]);
    Out.ar(\out.kr(0), sig ! 2);
}).add;

SynthDef(\drumfx, {
    var sig, trig, env;

    sig = In.ar(\in.kr(-1), 2);
    trig = Impulse.kr(\rate.kr * 5);
    //trig = trig * ToggleFF.kr(Dust.kr(\rate.kr * 100));

    env = Env.perc(0.001, 0.1).kr(gate: trig);
    sig = Mix.ar([
        sig * \dry.kr(0.5),
        HPF.ar(sig, SinOsc.kr(0.1, add: 1, mul: 0.25) * 1500) * (1 - \dry.kr(0.5))
    ]);
    sig = Mix.ar([
        sig,
        CombC.ar(
            LPF.ar(sig, \lpf.kr(220)) * env,
            maxdelaytime: 5 * \rate.kr,
            delaytime: \rate.kr,
            decaytime: \rate.kr * 10
    )]);
    Out.ar(\out.kr(0), sig, SinOsc.kr(0.1, add: 1) * 0.5);
}).add;
)