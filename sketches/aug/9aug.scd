
s.options.memSize_(65536 * 4);
s.reboot;

(

/*SynthDef(\drone, {
    var sig, env, rev, freq;

    sig = Pulse.ar(
        Saw.ar(\freq.kr(440), SinOsc.kr(100)),
        SinOsc.ar(\freq.kr(440)),
        SinOsc.ar(\freq.kr(440) / 2));

    env = EnvGen.kr(
        Env.perc(\atk.kr(0.05), \rel.kr(10)),
        \gate.kr(1),
        Done.freeSelf);

    sig = sig!2 * env;

    sig = sig * \vol.kr(1);

    Out.ar(\out.kr(0), sig);
}).add;*/

SynthDef(\drone, {
    var sig, env, rev, freq, chaos, bitcrush, ring, stutter;

    // Add some chaotic frequency modulation
    chaos = LorenzL.ar(
        freq: SinOsc.ar(0.1).range(10, 100),
        s: 10, r: 28, b: 1/3,
        h: 0.01,
        xi: 0.1, yi: 0, zi: 0
    ) * 50;

    sig = Pulse.ar(
        Saw.ar(\freq.kr(440) + chaos, SinOsc.kr(LFNoise1.kr(0.5).range(50, 200))),
        SinOsc.ar(\freq.kr(440) + LFNoise0.kr(10).range(-100, 100)).clip(0.1, 0.9),
        SinOsc.ar(\freq.kr(440) / 2 + LFNoise2.kr(0.3).range(-50, 50)));

    // Glitchy envelope with random stutters
    stutter = LFPulse.kr(
        LFNoise1.kr(0.2).range(5, 20),
        width: LFNoise1.kr(0.5).range(0.1, 0.8)
    );

    env = EnvGen.kr(
        Env.perc(\atk.kr(0.05), \rel.kr(10)),
        \gate.kr(1),
        doneAction: Done.freeSelf) * stutter;

    // Ring modulation madness
    ring = sig * SinOsc.ar(LFNoise1.kr(0.1).range(100, 2000));

    // Bitcrushing
    bitcrush = sig.round(LFNoise2.kr(2).range(0.01, 0.5));

    // Chaotic mix
    sig = SelectX.ar(
        LFNoise1.kr(0.3).range(0, 2),
        [sig, ring, bitcrush]
    );

    // Random panning chaos
    sig = Pan2.ar(sig, LFNoise1.kr(LFNoise0.kr(0.5).range(0.1, 5)).range(-1, 1));

    // Occasional dropouts
    sig = sig * LFPulse.kr(
        LFNoise0.kr(0.1).range(0.5, 8),
        width: LFNoise1.kr(0.2).range(0.3, 0.95)
    );

    sig = sig * env * \vol.kr(0.2); // Lower volume for safety!

    Out.ar(\out.kr(0), sig);
}).add;

SynthDef(\kick, {
    var sig, env, freqEnv, clickEnv, click;

    // Frequency envelope - starts high and drops quickly for that "thump"
    freqEnv = EnvGen.kr(
        Env([100, 50], [0.02], \exp),
        \gate.kr(1)
    );

    // Main amplitude envelope
    env = EnvGen.kr(
        Env.perc(\atk.kr(0.01), \rel.kr(0.5)),
        \gate.kr(1),
        doneAction: Done.freeSelf
    );

    // Click envelope for the attack transient
    clickEnv = EnvGen.kr(
        Env([0, 1, 0], [0.001, 0.01], \exp),
        \gate.kr(1)
    );

    // Main body - sine wave with frequency envelope
    sig = SinOsc.ar(freqEnv) * env;

    // Add some click/punch to the attack
    click = WhiteNoise.ar * clickEnv * 0.1;

    // Combine and shape
    sig = (sig + click / 2);

    // Optional light distortion for character
    sig = (sig * 2).tanh * \vol.kr(1.5);

    Out.ar(\out.kr(0), sig ! 2);
}).add;

SynthDef(\snare, {
    var sig, env, noise, tone, snap, rattle;

    // Main envelope
    env = EnvGen.kr(
        Env([0, 1, 0.3, 0], [\atk.kr(0.01), 0.05, \rel.kr(0.2)], [4, -2, -4]),
        \gate.kr(1),
        doneAction: Done.freeSelf
    );

    // Sharp attack envelope for the "snap"
    snap = EnvGen.kr(
        Env([0, 1, 0], [0.001, 0.01], \exp),
        \gate.kr(1)
    );

    // Noise component (main body)
    noise = WhiteNoise.ar * env;

    // High-frequency emphasis for snare "sizzle"
    noise = HPF.ar(noise, \hpf.kr(200));
    noise = BPF.ar(noise, \freq.kr(2000), 2) + (noise * 0.3);

    // Tonal component (snare shell resonance)
    tone = SinOsc.ar(\pitch.kr(200)) * env * 0.2;
    tone = tone + (SinOsc.ar(\pitch.kr(200) * 1.6) * env * 0.1);

    // Clap-like multiple hits (for that hand clap feel)
    rattle = Decay.ar(
        Impulse.ar([0, 0.01, 0.02]),
        0.01,
        WhiteNoise.ar
    ).sum * snap * 0.5;

    // Combine elements
    sig = noise + tone + rattle;

    // Shape and compress
    sig = sig * \amp.kr(0.6);
    sig = (sig * 2).tanh * 0.7; // Soft compression/saturation

    Out.ar(\out.kr(0), sig ! 2);
}).add;

SynthDef(\clicky, {
    var sig, env, click, body, pop, snap;

    // Super tight click envelope
    click = EnvGen.kr(
        Env([0, 1, 0], [0.0001, 0.001], \exp),
        \gate.kr(1)
    );

    // Main envelope
    env = EnvGen.kr(
        Env([0, 1, 0], [\atk.kr(0.001), \rel.kr(0.05)], \exp),
        \gate.kr(1),
        doneAction: Done.freeSelf
    );

    // Filtered noise burst
    snap = BPF.ar(
        WhiteNoise.ar,
        2000,
        0.1
    ) * click * 2;

    // Tiny bit of tonal body (optional)
    body = SinOsc.ar(\freq.kr(800)) * env * 0.3;

    // High-freq crackle
    sig = HPF.ar(
        PinkNoise.ar * click,
        1500
    ) * 3;

    // Combine all elements
    sig = (snap + sig + body) * \amp.kr(0.5);

    // Hard limiting to prevent clipping from the sharp transients
    sig = sig.clip2(0.8);

    Out.ar(\out.kr(0), sig ! 2);
}).add;

)

(
/*var main = Routine({
    inf.do({
        arg cycle;
        var kd = Routine({
            var step = 5;
            step.do({
                arg i;
                var sub = (1/step) / 2;
                Synth(\kick, [\vol, 3]);
                sub.wait;
                if (i % 2 == 0, {
                    Synth(\clicky, [\amp, 1]);
                });
                if (((i + 1) % 2 == 0) && (cycle % 2 == 0), {
                    Synth(\snare, [\amp, 1]);
                });
                sub.wait;
            });
        });
        cycle = cycle + 1;
        kd.play;
        1.wait;
    });
});
main.play;*/
)

(
// Set tempo (BPM)
~tempo = 140;
~beatDur = 60 / ~tempo / 4; // 16th note duration

// Define the break pattern (classic Amen-style)
// K = kick, S = snare, C = clicky, . = rest
~pattern = [
    "K.KCK.K.",
];

// Convert pattern to events
~parsePattern = { |patternString|
    patternString.as(Array).collect({ |char|
        switch(char,
            $K, [\kick, 0.9],
            $S, [\snare, 0.5],
            $C, [\clicky, 0.3],
            $., [nil, 0]
        );
    });
};

// Main drum routine
~drumBreak = Routine({
    inf.do({
        ~pattern.do({ |bar|
            var events;
            events = ~parsePattern.value(bar);
            events.do({ |event|
                var instrument = event[0];
                var amp = event[1];

                // Play the drum hit if not a rest
                if(instrument.notNil, {
                    Synth(instrument, [\amp, amp]);
                });

                // Wait for next 16th note
                ~beatDur.wait;
            });
        });
    });
});

// Ghost notes routine (subtle extra hits)
~ghostNotes = Routine({
    inf.do({
        // Random ghost snare hits
        if(0.3.coin, {
            (~beatDur * rrand(0.5, 3.5)).wait;
            Synth(\snare, [\amp, 0.15, \rel, 0.05]);
        });

        // Random clicky fills
        if(0.2.coin, {
            (~beatDur * rrand(1, 7)).wait;
            3.do({
                Synth(\clicky, [\amp, 0.2, \freq, rrand(1000, 3000)]);
                (~beatDur * 0.25).wait;
            });
        });

        (~beatDur * 16).wait; // Wait a full pattern cycle
    });
});

// Start the break
"Starting drum break...".postln;
~drumBreak.play;
//~ghostNotes.play;
)

// Stop everything
(
~drumBreak.stop;
~ghostNotes.stop;
"Drum break stopped.".postln;
)

// Tempo control
(
~tempo = 80;
~beatDur = 60 / ~tempo / 4;
)

// Different pattern (more complex)
(
~pattern = [
    "K.CK",
    "K.CK.",
];
)