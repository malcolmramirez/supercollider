Server.default.options.outDevice_("Macbook Pro Speakers");

s.boot;
s.quit;

s.scope;

// SynthDefs
(

SynthDef.new(\osc, {
    arg buf, freq,
        lpf,
        period, phase,
        modRatio = 2, index = 1,
        amp = 0.25, atk = 0.1, sus = 0.1, rel = 2,
        out;

    var sig, env;

    env = EnvGen.ar(
        Env.new(
            [0, 1, 1, 0],
            [atk, sus, rel]),
        doneAction:2);
    sig = Osc.ar(buf, freq);
    sig = LPF.ar(sig, lpf * SinOsc.kr(period, phase + pi/2, mul:0.5, add:1));

    sig = sig * env * amp * SinOsc.kr(period, phase, mul:0.5, add:1);

    // Safety processing - remove DC offset and clip.
    sig = LeakDC.ar(sig);
    sig = sig.softclip;

    Out.ar(out, sig!2);
}).add;

SynthDef.new(\reverb, {
    arg in, out,
        mix = 1, room = 0.99, damp = 0.25,
        amp = 1.0;

    var sig, reverbed;

    sig = In.ar(in, 2);
    sig = FreeVerb2.ar(
        sig[0],
        sig[1],
        mix,
        room,
        damp
    );

    sig = sig * amp;
    sig = sig.softclip;

    Out.ar(out, sig);
}).add;

)

(

var wtgen, wtosc,
    rev, rbus,
    drone, sunspots;

wtgen = {
    arg buf,
    numPoints=20, timeRange=10, curveRange=20;

    var env = Env.new(
        Array.rand(numPoints, -1.0, 1.0),
        Array.rand(numPoints, 1, timeRange),
        Array.rand(numPoints, -1 * curveRange, curveRange)
    );

    buf.loadCollection(env.asSignal(1024).asWavetable);
};

wtosc = {
    arg dur, octave, period, amp, phase, lpf, degree;

    var wbuf;

    wbuf = Buffer.alloc(s, 2048);

    Pbind(
        \instrument, \osc,
        \dur, dur,
        \buf, Pfuncn( { wtgen.value(wbuf) }, repeats:inf),
        \lpf, lpf,
        \scale, Scale.phrygian,
        \degree, degree,
        \octave, octave,
        \amp, amp,
        \period, period,
        \phase, phase,
        \atk, Pkey(\dur, repeats:inf) * 1/5,
        \sus, Pkey(\dur, repeats:inf) * 4/5,
        \rel, Pkey(\dur, repeats:inf) * 2,
        \out, rbus);
};

rbus = Bus.audio(s, 2);
rev = Synth.new(
    \reverb,
    [
        \in, rbus,
        \out, 0,
        \amp, 0.75
    ]);

// Add more "waves"
Scale.phrygian.degrees.postln;

drone = wtosc.value(
    dur:Prand([2, 4, 8], repeats:inf),
    octave:Prand([3, 4], repeats:inf),
    period:Pkey(\dur, repeats:inf).reciprocal,
    degree:Prand([1, 2, 6], repeats:inf),
    amp:0.015,
    phase:0,
    lpf:250);

sunspots = wtosc.value(
    dur:Prand([1/8, 1/4, 1/2], repeats:inf),
    octave:Prand([5, 6], repeats:inf),
    period:Pkey(\dur, repeats:inf).reciprocal,
    degree:Prand([0, 2, 6, 7], repeats:inf),
    amp:Pexprand(0.0001, 0.005),
    phase:Pwhite(0, 2*pi),
    lpf:1500);


Ppar([
    drone,
    sunspots
]).play;

)
