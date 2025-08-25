(
// 8 Interesting and Varied Percussive SuperCollider SynthDefs

// 1. KICK - Analog-style kick drum with pitch sweep and distortion
SynthDef(\kick, {
    arg out = 0, freq = 60, decay = 0.4, amp = 0.8, pitchRatio = 8, drive = 2;
    var env, pitch, sig, click;

    // Pitch envelope - starts high and drops quickly
    pitch = freq * EnvGen.kr(
        Env([pitchRatio, 1, 1], [0.02, decay - 0.02], [3, -4]),
        doneAction: 2
    );

    // Main body - sine wave with slight distortion
    sig = SinOsc.ar(pitch);
    sig = (sig * drive).tanh;

    // Click envelope for attack
    click = WhiteNoise.ar * EnvGen.kr(Env.perc(0.001, 0.01), levelScale: 0.1);

    // Main amplitude envelope
    env = EnvGen.kr(Env.perc(0.01, decay, curve: -8));

    sig = (sig + click) * env * amp;
    Out.ar(\out.kr(0), sig ! 2);
}).add;

// 2. SNARE - Layered snare with filtered noise and tonal component
SynthDef(\snare, {
    |out = 0, freq = 200, decay = 0.2, amp = 0.7, tone = 0.5, snap = 0.3|
    var env, noise, tonal, sig;

    // Main envelope
    env = EnvGen.kr(Env.perc(0.01, decay, curve: -4), doneAction: 2);

    // Noise component - filtered white noise
    noise = WhiteNoise.ar;
    noise = BPF.ar(noise, freq * 2, 0.5) + HPF.ar(noise, 1000);
    noise = noise * (1 - tone);

    // Tonal component - detuned oscillators
    tonal = SinOsc.ar([freq, freq * 1.5, freq * 2.1]);
    tonal = Mix(tonal) * tone * 0.3;

    // Snap component - short burst of filtered noise
    snap = BPF.ar(WhiteNoise.ar, 3000, 0.1) *
           EnvGen.kr(Env.perc(0.001, 0.05)) * snap;

    sig = (noise + tonal + snap) * env * amp;
    Out.ar(out, sig ! 2);
}).add;

// 3. HIHAT - Metallic hihat with band-pass filtered noise
SynthDef(\hihat, {
    |out = 0, decay = 0.1, amp = 0.6, freq = 8000, res = 0.8, open = 0|
    var env, sig, noise;

    // Different envelopes for closed vs open hihat
    env = Select.kr(open > 0.5, [
        EnvGen.kr(Env.perc(0.001, decay * 0.3, curve: -8)),  // Closed
        EnvGen.kr(Env.perc(0.001, decay, curve: -3))         // Open
    ]);

    // Multi-band filtered noise for metallic character
    noise = WhiteNoise.ar;
    sig = Mix([
        BPF.ar(noise, freq, res),
        BPF.ar(noise, freq * 1.4, res),
        BPF.ar(noise, freq * 2.1, res),
        HPF.ar(noise, freq * 0.7)
    ]);

    sig = sig * env * amp * EnvGen.kr(Env.new, doneAction: 2);
    Out.ar(out, sig ! 2);
}).add;

// 4. FM_PERC - FM synthesis percussion with complex modulation
SynthDef(\fm_perc, {
    |out = 0, freq = 440, decay = 0.3, amp = 0.8, ratio = 2.1, index = 8|
    var env, mod, car, sig;

    // Envelope affects both amplitude and modulation index
    env = EnvGen.kr(Env.perc(0.01, decay, curve: -6), doneAction: 2);

    // Modulator frequency
    mod = SinOsc.ar(freq * ratio) * (freq * index * env);

    // Carrier with modulation
    car = SinOsc.ar(freq + mod);

    // Additional harmonic content
    sig = car + (SinOsc.ar(freq * 0.5 + (mod * 0.3)) * 0.3);

    sig = sig * env * amp;
    Out.ar(out, sig ! 2);
}).add;

// 5. CLAP - Hand clap simulation with multiple filtered noise bursts
SynthDef(\clap, {
    |out = 0, decay = 0.2, amp = 0.7, spread = 0.02|
    var env, sig, delays;

    // Multiple delayed noise bursts to simulate hand clap
    delays = [0, spread, spread*2, spread*3, spread*5];

    sig = Mix.fill(5, { |i|
        var noise, filtered, localEnv;

        // Staggered envelopes
        localEnv = EnvGen.kr(
            Env.perc(0.001, decay * [1, 0.8, 0.6, 0.4, 0.3][i]),
            gate: Impulse.kr(0, delays[i])
        );

        noise = WhiteNoise.ar;
        filtered = BPF.ar(noise, [800, 1200, 1600], 0.3);
        Mix(filtered) * localEnv * [1, 0.7, 0.5, 0.3, 0.2][i];
    });

    sig = sig * amp * EnvGen.kr(Env.new, doneAction: 2);
    Out.ar(out, sig ! 2);
}).add;

// 6. METALLIC - Metallic percussion using ring modulation
SynthDef(\metallic, {
    |out = 0, freq = 300, decay = 0.8, amp = 0.6, ring_freq = 47, detune = 0.1|
    var env, osc1, osc2, ring, sig;

    env = EnvGen.kr(Env.perc(0.01, decay, curve: -3), doneAction: 2);

    // Two slightly detuned oscillators
    osc1 = SinOsc.ar(freq);
    osc2 = SinOsc.ar(freq * (1 + detune));

    // Ring modulation for metallic character
    ring = SinOsc.ar(ring_freq);

    sig = (osc1 + osc2) * ring * 0.5;

    // Add some filtered noise for texture
    sig = sig + (BPF.ar(WhiteNoise.ar, freq * 2, 0.1) * 0.2);

    sig = sig * env * amp;
    Out.ar(out, sig ! 2);
}).add;

// 7. WOOD_BLOCK - Percussive wooden sound using formant filtering
SynthDef(\wood_block, {
    |out = 0, freq = 800, decay = 0.15, amp = 0.8, wood = 0.7|
    var env, sig, exciter, formants;

    env = EnvGen.kr(Env.perc(0.005, decay, curve: -4), doneAction: 2);

    // Exciter - brief burst of filtered noise
    exciter = BPF.ar(WhiteNoise.ar, freq * 4, 0.1) *
              EnvGen.kr(Env.perc(0.001, 0.02));

    // Formant-like resonances for woody character
    formants = Mix([
        Resonz.ar(exciter, freq, 0.02),
        Resonz.ar(exciter, freq * 2.3, 0.03),
        Resonz.ar(exciter, freq * 3.7, 0.04),
        Resonz.ar(exciter, freq * 5.1, 0.05)
    ]);

    // Blend with direct exciter signal
    sig = LinXFade2.ar(exciter, formants, wood * 2 - 1);

    sig = sig * env * amp * 3; // Compensate for resonz attenuation
    Out.ar(out, sig ! 2);
}).add;

// 8. GLITCH_PERC - Glitchy digital percussion with bit crushing and delays
SynthDef(\glitch_perc, {
    |out = 0, freq = 200, decay = 0.4, amp = 0.7, crush = 8, delay_time = 0.1|
    var env, sig, delayed, crushed;

    env = EnvGen.kr(Env.perc(0.01, decay, curve: -2), doneAction: 2);

    // Start with FM synthesis
    sig = SinOsc.ar(freq + (SinOsc.ar(freq * 3.3) * freq * 2 * env));

    // Add some filtered noise
    sig = sig + (BPF.ar(WhiteNoise.ar, freq * 2, 0.3) * 0.3);

    // Bit crushing for digital artifacts
    crushed = Decimator.ar(sig, 44100, crush);

    // Delays for glitchy echoes
    delayed = CombC.ar(crushed, 0.2, delay_time, decay * 0.3);
    delayed = delayed + CombC.ar(crushed, 0.2, delay_time * 0.7, decay * 0.2);

    sig = crushed + (delayed * 0.4);

    // Occasional random filter sweeps
    sig = LPF.ar(sig, freq * (2 + (LFNoise1.kr(20) * 3).max(0)));

    sig = sig * env * amp;
    Out.ar(out, sig ! 2);
}).add;

)
/*
USAGE EXAMPLES:

// Test each synth
Synth(\kick, [\freq, 50, \decay, 0.6]);
Synth(\snare, [\freq, 200, \tone, 0.7]);
Synth(\hihat, [\decay, 0.08, \open, 0]);  // Closed hihat
Synth(\hihat, [\decay, 0.3, \open, 1]);   // Open hihat
Synth(\fm_perc, [\freq, 120, \ratio, 3.2, \index, 12]);
Synth(\clap);
Synth(\metallic, [\freq, 400, \ring_freq, 31]);
Synth(\wood_block, [\freq, 1000, \wood, 0.9]);
Synth(\glitch_perc, [\freq, 150, \crush, 6, \delay_time, 0.08]);
*/

// Simple pattern example
(
// Tempo and timing setup
~tempo = 140; // BPM
~beat = 60 / ~tempo; // Quarter note duration
TempoClock.default.tempo = ~tempo / 60;

// Main breakbeat pattern - 2 bars (32 sixteenth notes)
~breakbeat = Ppar([
    // KICK pattern - Classic Amen positions
    Pbind(
        \instrument, \kick,
        \dur, Pseq([
            ~beat, ~beat*1.5, ~beat*0.5, ~beat, // Bar 1
            ~beat*2, ~beat*2                     // Bar 2
        ], inf),
        \freq, Pseq([45, 48, 50, 52, 45, 40], inf),
        \amp, Pseq([0.9, 0.8, 0.85, 0.7, 0.95, 0.85], inf),
        \decay, 0.5,
        \pitchRatio, 6
    ),

    // SNARE pattern - Backbeats and ghost notes
    Pbind(
        \instrument, \snare,
        \dur, Pseq([
            Rest(~beat), ~beat, Rest(~beat), ~beat*0.5, Rest(~beat*0.5), // Bar 1
            Rest(~beat*0.5), ~beat*0.5, Rest(~beat), ~beat, Rest(~beat)  // Bar 2
        ], inf),
        \freq, Pseq([200, 180, 220, 190, 210, 185], inf),
        \amp, Pseq([0.8, 0.4, 0.9, 0.3, 0.85, 0.7], inf), // Ghost notes quieter
        \tone, Pseq([0.6, 0.8, 0.5, 0.9, 0.4, 0.7], inf),
        \decay, 0.2
    ),

    // HIHAT pattern - Steady 16th notes with variations
    Pbind(
        \instrument, \hihat,
        \dur, ~beat * 0.25, // 16th notes
        \amp, Pseq([
            // Bar 1
            0.3, 0.2, 0.4, 0.1, 0.3, 0.2, 0.5, 0.15,
            0.3, 0.2, 0.4, 0.1, 0.3, 0.25, 0.4, 0.1,
            // Bar 2
            0.3, 0.2, 0.4, 0.1, 0.3, 0.2, 0.4, 0.1,
            0.3, 0.2, 0.4, 0.1, 0.3, 0.2, 0.5, 0.15
        ], inf),
        \open, Pseq([
            // Occasional open hihats
            0, 0, 0, 0, 0, 0, 1, 0,  // Open on 7th 16th
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 1, 0   // Open on 31st 16th
        ], inf),
        \decay, Pif(Pkey(\open) > 0.5, 0.25, 0.08),
        \freq, 9000,
        \res, 0.7
    ),

    // CLAP - Accent on certain beats
    Pbind(
        \instrument, \clap,
        \dur, Pseq([
            Rest(~beat*2), Rest(~beat*2),        // Bar 1 - no clap
            Rest(~beat), ~beat, Rest(~beat*2)    // Bar 2 - clap on beat 2
        ], inf),
        \amp, 0.6,
        \spread, 0.015,
        \decay, 0.15
    ),

    // FM_PERC - Melodic percussion fills
    Pbind(
        \instrument, \fm_perc,
        \dur, Pseq([
            Rest(~beat*3), ~beat*0.25, Rest(~beat*0.75), // Bar 1 - quick fill
            Rest(~beat*4)                                 // Bar 2 - rest
        ], inf),
        \freq, Pseq([300, 400, 250, 350 * sqrt(5)], inf),
        \amp, 0.4,
        \ratio, Pseq([2.1, 3.3, 1.7, 2.8], inf),
        \index, 6,
        \decay, 0.2
    ),

    // METALLIC - Sparse accents
    Pbind(
        \instrument, \metallic,
        \dur, Pseq([
            Rest(~beat*6), ~beat*0.5, Rest(~beat*1.5)  // Every 2 bars
        ], inf),
        \freq, Pseq([800, 600 * sqrt(5), 1000], inf),
        \amp, 0.3,
        \ring_freq, Pseq([47, 71, 63 * sqrt(5)], inf),
        \decay, 0.6,
        \detune, 0.08
    ),

    // WOOD_BLOCK - Percussive accents
    Pbind(
        \instrument, \wood_block,
        \dur, Pseq([
            Rest(~beat*4),                          // Bar 1 - rest
            Rest(~beat*1.5), ~beat*0.25, ~beat*0.25, Rest(~beat*2) // Bar 2 - quick double hit
        ], inf),
        \freq, Pseq([1200, 1000, 1400], inf),
        \amp, 0.5,
        \wood, 0.8,
        \decay, 0.1
    ),

    // GLITCH_PERC - Glitchy fills and textures
    Pbind(
        \instrument, \glitch_perc,
        \dur, Pseq([
            Rest(~beat*7), ~beat*0.125, Rest(~beat*0.875) // Occasional glitch hit
        ], inf),
        \freq, Pseq([150, 200, 100, 250 * sqrt(5)], inf),
        \amp, 0.4,
        \crush, Pseq([8, 6, 10, 4], inf),
        \delay_time, Pseq([0.08, 0.12, 0.06, 0.1], inf),
        \decay, 0.3
    )
], inf);

// Start the pattern
~breakbeat.play;
)
