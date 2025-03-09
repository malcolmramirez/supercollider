Server.default.options.outDevice_("Macbook Pro Speakers");

s.boot;
s.quit;

s.scope;

// SynthDefs
(

SynthDef.new(\osc, {
    arg buf, freq,
    lpf,
    modRatio = 2, index = 1,
    amp = 0.25, atk = 0.1, sus = 0.1, rel = 2,
    out;

    var sig, env, mod;
    env = EnvGen.ar(
        Env.new(
            [0, 1, 1, 0],
            [atk, sus, rel]),
        doneAction:2);
    sig = Osc.ar(buf, freq + mod);
    sig = LPF.ar(sig, lfp);
    sig = sig * env * amp;

    // Safety processing - remove DC offset and clip.
    sig = LeakDC.ar(sig);
    sig = sig.softclip;

    Out.ar(out, sig!2);
}).add;

SynthDef.new(\osc2, {
    arg buf, freq, amp,
    modRatio = 2, index = 1,
    out;

    var sig, env, mod;

    mod = Pulse.ar(freq, mul:freq * modRatio * index);
    sig = Osc.ar(buf, freq + mod);
    sig = sig * amp;

    // Safety processing - remove DC offset and clip.
    sig = LeakDC.ar(sig);
    sig = sig.softclip;

    Out.ar(out, sig!2);
}).add;

SynthDef.new(\noise, {
    arg amp, out;

    var sig;

    sig = PinkNoise.ar * amp;
    Out.ar(out, sig!2);
}).add;


SynthDef.new(\reverb, {
    arg in, out,
    mix = 0.75, room = 0.99, damp = 0.75,
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

SynthDef.new(\wavefx, {
    arg in, out,
    period = 1, phase = 0, lpf = 1000;

    var wavectl, sig;

    wavectl = SinOsc.ar(period, phase, add:1);
    sig = In.ar(in, 2);
    sig = LPF.ar(sig, lpf);
    sig = sig * wavectl;

    Out.ar(out, sig);
}).add;


)

Scale.directory;



(

var wtgen, chosenratio;

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

chosenratio = Scale.phrygian.ratios.choose;

~waves = (1..3).collect({
    arg item, i;

    var wbus, noise, wavefx, buf, tone, reverb, rbus;

    wbus = Bus.audio(s, 2);
    wavefx = Synth.new(
        \wavefx,
        [
            \in, wbus,
            \out, 0,
            \period, rrand(0.01, 0.1),
            \phase, rrand(0, 2*pi),
            \lpf, rrand(1000, 4000)
    ]);
    noise = Synth.before(
        wavefx,
        \noise,
        [
            \out, wbus,
            \amp, rrand(0.01, 0.05)
    ]);

    rbus = Bus.audio(s, 2);
    reverb = Synth.before(
        wavefx,
        \reverb,
        [
            \in, rbus,
            \out, wbus
    ]);

    buf = Buffer.alloc(s, 2048);
    wtgen.value(buf);

    tone = Synth.before(
        reverb,
        \osc2,
        [
            \buf, buf,
            \freq, (110 * item) * chosenratio,
            \amp, rrand(0.001, 0.005),
            \out, rbus
    ]);
    [wbus, wavefx, noise, buf, tone, rbus, reverb]
});

)

(

~waves.do({
    arg ar;
    ar.do({
        arg item;
        item.free;
    });
});

)

(

var wtgen, rev, wave;

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

rev = Synth(
    \reverb,
    [
        \input, rbus,
        \out, 0,
        \amp, 0.75
]);


wave = {
    arg dur, repeats, octave, period, amp, degree, phase;

    var wBuf = Buffer.alloc(s, 2048);
    Pbind(
        \instrument, \osc,
        \dur, dur,
        \buf, Pfuncn( { wtGen.value(wBuf) }, repeats:repeats),
        \lpf, Pexprand(1500, 5000, repeats:repeats),
        \scale, Scale.phrygian,
        \degree, Pfuncn( { Scale.phrygian.degrees.choose }, repeats:repeats),
        \octave, octave,
        \amp, amp,
        \atk, Pkey(\dur, repeats:repeats) * 1/5,
        \sus, Pkey(\dur, repeats:repeats) * 4/5,
        \rel, Pkey(\dur, repeats:repeats) * 2,
        \dry, Ptime().collect({ arg t; sin(t * period + phase) + 1 }).trace,
        \wet, Ptime().collect({ arg t; cos(t * period + phase) + 1 }).trace,
        \out, rbus);
};

// Add more "waves"

~wave1 = wave.value(4, inf, 3, 3, 0.35, phase:0);
~pT = Ppar([~wave1]).play;
)
