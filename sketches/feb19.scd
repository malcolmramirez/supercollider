s.boot;
s.quit;

(
SynthDef(
    \mine,
    {  arg freq = 440, atk = 0.005, rel = 0.3, amp = 1, pan = 0;
        var env = EnvGen.kr(
            Env.new([0, 1, 0], [atk, rel]),
            doneAction:2
        );

        var sig = SinOsc.ar(freq);
        sig = Pan2.ar(sig, pan, amp);

        Out.ar(0, sig * env);
}).add;
)

(
p = Pbind(
    \instrument, \mine,
    \type, \note,
    \midinote, 30,
    \harmonic, Prand([4, 7, 10], inf),
    \dur, Pwhite(0.25, 1, inf),
    \amp, Pkey(\harmonic).reciprocal * Pwhite(0, 1, inf) * 0.5,
    \rel, Pwhite(3, 9, inf)
).play;
)

